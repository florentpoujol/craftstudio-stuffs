/// <summary>
/// ScriptFileHandler.cs
/// Part of the CraftStudio Script Handler application
///
/// Copyright © 2013-2014 Florent POUJOL
/// http://florentpoujol.fr
/// </summary>

/*
structure of a .csscript file

octet       type        what
8                       ?
?           string      The code
2           uint        next property id
2           uint        properties count

    property
    2       uint        id
    ?       string      name
    1       byte        type (0 bool, 1 number, 2 string)
    ?       bool, double or string            value
*/

using UnityEngine;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;


/// <summary>
/// Holds data about a public property.
/// </summary>
public struct PublicProperty {
    public uint id; 
    public string name;
    public uint type;
    public object value;
}


/// <summary>
/// Holds data about one particular revision of a script asset.
/// </summary>
public class CSScriptRevision {
    public uint id;
    public string name = ""; // string to allow "Current" as a revision name
    public byte[] head;
    public string code = "";

    public uint nextPropertyId;
    public uint propertiesCount = 0;
    public Dictionary<uint, PublicProperty> properties = new Dictionary<uint, PublicProperty>();
}


/// <summary>
/// Holds data about a script asset.
/// Can read any revision and provide its content (including public properties) as a string.
/// Can write any revision from a string containing the asset's code and public property.
/// </summary>
public class ScriptFileHandler : Asset {
    public Dictionary<string, CSScriptRevision> revisions = new Dictionary<string, CSScriptRevision>();
    string newLine = "\n"; // unix

    /// <summary>
    /// Constructor, initialize a CSScriptHandler instance from an Asset instance
    /// </summary>
    /// <param name="asset">The Asset instance</param>
    public ScriptFileHandler( Asset asset ) {
        projectHandler = asset.projectHandler;
        id = asset.id;
        name = asset.name;
        type = asset.type; // 7

        nextRevisionId = asset.nextRevisionId;
        revisionsCount = asset.revisionsCount;
        revisionNames = asset.revisionNames;

        isFolder = asset.isFolder;
        folderId = asset.folderId;
        isTrashed = asset.isTrashed;

        path = projectHandler.projectPath + "/Assets/Scripts/" + id;
    }


    /// <summary>
    /// Gat all the .csscript revisions files for that script
    /// and make them read by ReadRevisionFile()
    /// </summary>
    public void Read() {
        string[] files = Directory.GetFiles( path );
        if( files.Length == 0 ) {
            Debug.LogWarning( "No .csscript file to be read for script asset with ID " + id );
            return;
        }

        foreach( string revisionFile in files ) {
            ReadRevisionFile( revisionFile );
        }
    }


    /// <summary>
    /// Read the script's revision file of the provided path
    /// </summary>
    /// <param name="path">The revision file's full path (or name)</param>
    public void ReadRevisionFile( string path ) {
        if( ! path.Contains( ".csscript" ) ) {
            // assume the path is actually the revision name
            path = this.path + "/" + path + ".csscript";
        }

        BinaryReader binReader = new BinaryReader( File.Open( path, FileMode.Open ) );
        
        CSScriptRevision revision = new CSScriptRevision();
        revision.name = GetRevisionNameFromPath( path ); // from Asset parent class

        if( revision.name != "Current" ) {
            revision.id = Convert.ToUInt16( revision.name );
            revision.name = revisionNames[ revision.id ];
        }

        try {
            if( binReader.PeekChar() != -1 )
            {
                revision.head = binReader.ReadBytes( 8 );
                revision.code = binReader.ReadString();

                // public properties
                revision.propertiesCount = binReader.ReadUInt16(); // with .csscript only, "count" comes before "next id"
                revision.nextPropertyId = binReader.ReadUInt16();

                for( int i = 0; i < revision.propertiesCount; i++ ) {
                    PublicProperty property = new PublicProperty();

                    if( binReader.PeekChar() == -1 ) break;
                    property.id = binReader.ReadUInt16();
                    property.name = binReader.ReadString();
                    property.type = binReader.ReadByte();

                    if( property.id > revision.nextPropertyId || property.name.Trim() == "" ) break;

                    switch( property.type ) {
                        case 0: // boolean
                            property.value = binReader.ReadBoolean();
                        break;

                        case 1: // number
                            property.value = binReader.ReadDouble();
                        break;

                        case 2: // text
                            property.value = binReader.ReadString();
                        break;
                    }
                    
                    revision.properties.Add( property.id, property );
                }

                //revision.propertiesCount = (uint) revision.properties.Count; // the properties count is sometimes false

                revisions.Add( revision.name, revision );
            }
        }
        finally {
            binReader.Close();
        }
    } // end of ReadRevisionFile() method


    /// <summary>
    /// Get the content of a .csscript revision
    /// </summary>
    /// <param name="revisionName">The revision name to read from</param>
    /// <returns>The readable code and properties as a string</returns>
    public string GetLuaStringFromRevision( string revisionName ) {
        
        if( ! this.revisions.ContainsKey( revisionName ) ) {
            // find the last revision
            uint highest = 0;
            foreach( KeyValuePair<uint, string> pair in revisionNames ) {
                if( pair.Key > highest )
                    highest = pair.Key;
            }
            Debug.Log( "highest revision id " + highest + " for script name " + name );

            revisionName = this.revisionNames[ highest ]; // from Asset class
        }

        CSScriptRevision revision = this.revisions[ revisionName ];

        string luaCode = "";

        if( revision.properties.Count > 0 ) {
            luaCode = "--[[PublicProperties" + newLine;

            foreach( KeyValuePair<uint, PublicProperty> pair in revision.properties ) {
                string type = "boolean";
                switch( pair.Value.type ) {
                    case 1: type = "number"; break;
                    case 2: type = "string"; break;
                }

                if( type == "string" )
                    luaCode += pair.Value.name + " " + type + " \"" + pair.Value.value + '"' + newLine;
                else
                    luaCode += pair.Value.name + " " + type + " " + pair.Value.value + newLine;
            }

            luaCode += "/PublicProperties]]" + newLine;
        }

        luaCode += revision.code;

        return luaCode;
    }


    /// <summary>
    /// Write a .csscript revision from the content of a .lua script
    /// </summary>
    /// <param name="luaString">The content of the .lua script</param>
    /// <param name="revisionName">The name of the revision to write [optional default="Current"]</param>
    public void WriteRevisionFromLuaString( string luaString, string revisionName = "Current" ) {
        luaString = luaString.Replace( "\r\n", newLine ).Replace( "\r", newLine ); // replace windows and mac line ending by Unix's

        // Extract the properties
        string pattern = "(--\\[\\[PublicProperties)(?<properties>.*?)(/PublicProperties\\]\\])"; // the ? after the .* makes (/PublicProperties\\]\\]) match only the first occurence, prevent matching other thing that public properties lines
        Match match = Regex.Match( luaString, pattern, RegexOptions.Singleline );
        List<PublicProperty> propertiesList = new List<PublicProperty>();

        if( match.Success ) {
            luaString = luaString.Replace( match.Groups[0].Value, "" ).TrimStart( newLine.ToCharArray()[0] );

            string[] properties = match.Groups["properties"].Value.Split( newLine.ToCharArray()[0] );
            uint propertyId = 0;
            Debug.Log("property bloc : " + match.Groups["properties"].Value);

            foreach( string _property in properties ) {
                string propertyString = _property.Trim();
                if( propertyString == "" ) continue;
                Debug.Log("propertyString : " + propertyString);

                PublicProperty property = new PublicProperty();
                property.id = propertyId++;
                int separationIndex = propertyString.IndexOf( " " );
                property.name = propertyString.Substring( 0, separationIndex ).Trim();
                propertyString = propertyString.Substring( separationIndex + 1 ).TrimStart();

                separationIndex = propertyString.IndexOf( " " );
                string type = propertyString.Substring( 0, separationIndex ).Trim().ToLower();
                
                propertyString = propertyString.Substring( separationIndex + 1 ).TrimStart().Trim( '"' );
                
                switch( type ) {
                    case "boolean": 
                        property.type = 0; 
                        property.value = Convert.ToBoolean( propertyString );
                    break;

                    case "number":
                        property.type = 1; 
                        property.value = Convert.ToDouble( propertyString );
                    break;

                    case "text":
                    case "string": 
                        property.type = 2;
                        property.value = propertyString;
                    break;
                }             

                propertiesList.Add( property );
            }
        }


        // write the .csscript
        BinaryWriter binWriter = new BinaryWriter( File.Open( this.path + "/" + revisionName + ".csscript", FileMode.Create ) );

        binWriter.Write( this.revisions[ revisionName ].head );
        binWriter.Write( luaString ); // the code

        binWriter.Write( Convert.ToUInt16( propertiesList.Count ) );
        binWriter.Write( Convert.ToUInt16( propertiesList.Count ) );

        foreach( PublicProperty property in propertiesList ) {
            binWriter.Write( Convert.ToUInt16( property.id ) );
            binWriter.Write( property.name );
            binWriter.Write( Convert.ToByte( property.type ) );

            switch( property.type ) {
                case 0: binWriter.Write( (bool) property.value );
                break;
                case 1: binWriter.Write( Convert.ToDouble( property.value ) );
                break;
                case 2: binWriter.Write( (string) property.value );
                break;
            }
        }
        
        binWriter.Flush();
        binWriter.Close();
    } // end of WriteRevisionFromLuaString() method
} // end of SripFileHandler class
