/// <summary>
/// CSScript.cs
///
/// Holds data about a .csscript file (CraftStudio's scripts).
/// Allow to read/write a .csscript file and provide its content (including public properties) in regular Lua
///
/// http://florentpoujol.fr
/// </summary>

/*
Released under the MIT licence.

Copyright ©2013-2014 Florent POUJOL

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

using UnityEngine;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

public class CSScript {
    
    // Holds data about a public property.
    public class PublicProperty {
        public uint id; 
        public string name;
        public uint type;
        public object value;
    }


    //----------------------------------------------------------------------------------

    string mNewLine = "\n"; // unix

    string mPath = null;
    public string Path { // path of the .csscript
        get { return mPath; }
        set { 
            if (!File.Exists( value )) {
                Debug.LogError("CSScript.Path : Path '"+value+"' is not valid !");
                return;
            }
            
            string tPath = value.Trim().Replace( @"\", "/" );
            if (tPath != mPath) {
                mPath = tPath;
                IsRead = false;
            }

        }
    }
    public bool IsRead { get; private set; }
    
    public byte[] Head { get; private set; } // data before the luaCode
    public string LuaCode { get;  private set; }

    public uint PropertiesCount { get; private set; }
    public uint NextPropertyId { get; private set; }
    public Dictionary<uint, PublicProperty> PropertiesById { get; private set; }
    

    //----------------------------------------------------------------------------------

    public CSScript() {
        PropertiesById = new Dictionary<uint, PublicProperty>();
        IsRead = false;
    }


    //----------------------------------------------------------------------------------

    /// <summary>
    /// Read the .csscript file and update the instance's data.
    /// </summary>
    /// <param name="_path">The .csscript file's path. [optional]</param>
    /// <returns>True if the file has been read successfully.</returns>
    public bool Read( string _path = null ) {
        if (_path == null )            
            _path = Path;
        
        if (!File.Exists( _path )) {
            Debug.LogError("CSScript.Read() : Path '"+_path+"' is not valid !");
            return false;
        }

        // temp variables
        byte[] head = new byte[0];
        string luaCode = "";
        uint propertiesCount = 0;
        uint nextPropertyId = 0;
        Dictionary<uint, PublicProperty> propertiesById = new Dictionary<uint, PublicProperty>();


        BinaryReader binReader = new BinaryReader( File.Open( _path, FileMode.Open ) );
  
        try {
            if (binReader.PeekChar() != -1)
            {
                head = binReader.ReadBytes( 8 );
                luaCode = binReader.ReadString();

                // public properties
                propertiesCount = binReader.ReadUInt16(); // with .csscript only, "count" comes before "next id"
                nextPropertyId = binReader.ReadUInt16();

                for ( int i = 0; i < propertiesCount; i++ ) {
                    PublicProperty property = new PublicProperty();

                    if ( binReader.PeekChar() == -1 ) break;
                    property.id = binReader.ReadUInt16();
                    property.name = binReader.ReadString();
                    property.type = binReader.ReadByte();

                    if ( property.id > nextPropertyId || property.name.Trim() == "" ) break;

                    switch ( property.type ) {
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
                    
                    propertiesById.Add( property.id, property );
                }
            }
        }
        catch (Exception e) {
            Debug.LogError( e );
            return false;
        }
        finally {
            binReader.Close();
        }

        // all is well, we can safely update the instance's properties
        Path = _path;
        Head = head;
        LuaCode = luaCode;
        PropertiesCount = propertiesCount;
        NextPropertyId = nextPropertyId;
        PropertiesById = propertiesById;
        IsRead = true;
        return true;
    }


    /// <summary>
    /// Update the PropertiesById and LuaCode properties from the content of the provided lua code.
    /// </summary>
    /// <param name="_luaCode">The lua code.</param>
    public void Update( string _luaCode ) {
        _luaCode = _luaCode.Replace( "\r\n", mNewLine ).Replace( "\r", mNewLine ); // replace windows and mac line ending by Unix's
        
        // Extract and replace the properties
        string pattern = "(--\\[\\[PublicProperties)(?<properties>.*?)(/PublicProperties\\]\\])"; // the ? after the .* makes (/PublicProperties\\]\\]) match only the first occurrence, prevent matching other thing that public properties lines
        Match match = Regex.Match( _luaCode, pattern, RegexOptions.Singleline );
        Dictionary<uint, PublicProperty> propertiesById = new Dictionary<uint, PublicProperty>();

        if (match.Success) {
            // remove properties bloc from code
            _luaCode = _luaCode.Replace( match.Groups[0].Value, "" ).TrimStart( mNewLine.ToCharArray()[0] );

            string[] matchedProperties = match.Groups["properties"].Value.Split( mNewLine.ToCharArray()[0] );
            uint propertyId = 0;

            foreach (string prop in matchedProperties) {
                string propertyString = prop.Trim();
                if ( propertyString == "" ) continue;

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

                propertiesById.Add( property.id, property );
            }

            PropertiesById = propertiesById;
        }

        LuaCode = _luaCode;
    }


    /// <summary>
    /// Write the .csscript file with the content of the instance's data.
    /// If anything goes wrong, the file is left untouched.
    /// </summary>
    /// <param name="_path">The path of the .csscript file. [optional]</param>
    /// <param name="_luaCode">The lua code. [optional]</param>
    /// <returns>True if the file has been successfully written.</returns>
    public bool Write(  string _path = null, string _luaCode = null ) {
        if (_path == null )
            _path = Path;

        if (!File.Exists( _path )) {
            Debug.LogError("CSScript.Write() : Path '"+_path+"' is not valid !");
            return false;
        }

        if(_luaCode != null) 
            Update( _luaCode );

        
        string tempPath = _path.Replace( ".csscript", "_temp.csscript" );  // tempPath now ends by "/[filename]_temp.csscript"
        BinaryWriter binWriter = new BinaryWriter( File.Open( tempPath, FileMode.Create ) );

        try {
            binWriter.Write( Head );
            binWriter.Write( LuaCode );

            binWriter.Write( Convert.ToUInt16( PropertiesById.Count ) );
            binWriter.Write( Convert.ToUInt16( PropertiesById.Count ) );

            foreach( KeyValuePair<uint, PublicProperty> pair in PropertiesById ) {
                PublicProperty property = pair.Value;

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
        }
        catch (Exception e) {
            Debug.LogError( e );
            return false;
        }

        // now that all is well, swap the temp file with the original one
        File.Delete( _path );
        File.Move( tempPath, _path );

        return true;
    }


    /// <summary>
    /// Get the lua code with properties block at the top.
    /// Passing the path as argument force the file to be read again.
    /// </summary>
    /// <param name="_path">The path of the .csscript file. If exists, force the file to be read again.</param>
    /// <returns>The readable code and properties</returns>
    public string GetContent( string _path = null ) {
        if ( _path != null )
            Read( _path );

        if (!IsRead)
            Read();
        
        string luaCode = "";

        if (PropertiesById != null && PropertiesById.Count > 0) {
            luaCode = "--[[PublicProperties" + mNewLine;

            foreach (KeyValuePair<uint, PublicProperty> pair in PropertiesById) {
                PublicProperty property = pair.Value;

                string type = "boolean";
                switch (property.type) {
                    case 1: type = "number"; break;
                    case 2: type = "string"; break;
                }

                if (type == "string")
                    luaCode += property.name + " " + type + " \"" + property.value + '"' + mNewLine;
                else
                    luaCode += property.name + " " + type + " " + property.value + mNewLine;
            }

            luaCode += "/PublicProperties]]" + mNewLine;
        }

        luaCode += LuaCode;

        return luaCode;
    }
}
