/// <summary>
/// ProjectFileHandler.cs
/// Part of the CraftStudio Script Handler application
///
/// Copyright © 2013-2014 Florent POUJOL
/// http://florentpoujol.fr
/// </summary>

/*
Struture of the [project guid]/Project.dat file :

octet type       what

2     uint16     type of project (game or film)
?     string     project name
6     ?          ? (accessibility ans type of membership)
?     string     project description

Game controls

2     uint16     next game control id
2     uint16     game controls count
?     []          all game controls
    
    game control:
    2    uint16    id
    ?    string    name
    21   ?         ?

Assets 

2    uint16      next assets id
2    uint16      assets count
?    []          all assets

    asset
    1   byte     is folder (boolean)
    2   uint16   asset id (0 model, 1 document?, 2 scene, 3 map?, 4 tileset?, 5 ??, 6 model animation, 7 scripts, 8 sound, 9 Font)
    2   uint16   folder id (65535 when no folder)
    ?   string   asset name
    1   byte     asset type
    
    if not folder
        1   byte     is trashed (boolean) Trashed assets are written at the end of the file
        2   uint16   next revision id
        2   uint16   revision count
        ?   []       all revisions (if any)

            revision
            2    uint16    revision id
            ?    string    revision name

*/

using UnityEngine;
using System;
using System.Collections.Generic;
using System.IO;


/// <summary>
/// Holds data about a game control.
/// </summary>
public class GameControl {
    public uint id;
    public string name = "";
    public byte[] settings;
}


/// <summary>
/// Reads the "Project.dat" file in a CraftStudio project and holds it's data.
/// </summary>
public class ProjectFileHandler {
    public string projectPath = "";
    public string projectGuid = "";

    public bool isRead = false;
    
    public string path = "";
    public string name = "";
    public string description = "";

    public uint nextGameControlId;
    public uint gameControlsCount = 0;
    public Dictionary<uint, GameControl> gameControls = new Dictionary<uint, GameControl>();

    public uint nextAssetId;
    public uint assetsCount = 0;
    public Dictionary<uint, Asset> assets = new Dictionary<uint, Asset>();

    /// <summary>
    /// Contructor, set path and projectPath
    /// </summary>
    /// <param name="p_path">The path of the CS project folder or the Project.dat file</param>
    public ProjectFileHandler( string p_path ) {
        this.projectPath = p_path.Replace( "\\", "/" ).TrimEnd( '/' );

        if( this.projectPath.Contains( "Project.dat" ) ) {
            this.path = this.projectPath;
            this.projectPath = this.projectPath.Replace( "/Project.dat", "" );
        }
        else {
            this.path = this.projectPath + "/Project.dat";
        }

        this.projectGuid = this.projectPath.Substring( this.projectPath.LastIndexOf( "/" ) + 1 );
    }


    /// <summary>
    /// Read the Project.dat file
    /// </summary>
    public void Read() {
        try {
            BinaryReader binReader = new BinaryReader( File.Open( this.path, FileMode.Open ) );

            if( binReader.PeekChar() != -1 )
            {
                binReader.ReadUInt16(); // Type of project (game or film ?)
                name = binReader.ReadString();

                binReader.ReadBytes( 6 ); // accessibility and type of membership ?
                description = binReader.ReadString();

                // GameControls
                nextGameControlId = binReader.ReadUInt16();
                gameControlsCount = binReader.ReadUInt16();

                for( int i = 0; i < gameControlsCount; i++ ) {
                    GameControl control = new GameControl();
                    
                    control.id = binReader.ReadUInt16();
                    control.name = binReader.ReadString();
                    control.settings = binReader.ReadBytes( 21 );

                    gameControls.Add( control.id, control );
                }

                // Assets
                nextAssetId = binReader.ReadUInt16();
                assetsCount = binReader.ReadUInt16();
                
                // loop through the assets and folders
                for( int i = 0; i < assetsCount; i++ ) {
                    Asset asset = new Asset();
                    asset.projectHandler = this;

                    asset.isFolder = binReader.ReadBoolean();
                    asset.id = binReader.ReadUInt16();
                    asset.folderId = binReader.ReadUInt16(); // 65535 = no folder
                    
                    asset.name = binReader.ReadString();
                    asset.type = binReader.ReadUInt16();
                    
                    if( ! asset.isFolder ) {
                        asset.isTrashed = binReader.ReadBoolean();
                        asset.nextRevisionId = binReader.ReadUInt16();
                        asset.revisionsCount = binReader.ReadUInt16();

                        for( int j = 0; j < asset.revisionsCount ; j++ ) {
                            uint revId = binReader.ReadUInt16();
                            string revName = binReader.ReadString();
                            
                            asset.revisionNames.Add( revId, revName );
                        }
                    }

                    assets.Add( asset.id, asset );
                } // end looping assets
            }

            binReader.Close();
            isRead = true;
        }
        catch(Exception e) {
            isRead = false;
            Debug.LogError( e );
            CraftStudioScriptHandler.instance.consoleLines.Push( "ERROR : Couldn't read CraftStudio project. The path is wrong or your CraftStudio local server is still running. " + Environment.NewLine + e );
        }
    } // end of Read() method


    /// <summary>
    /// Return the fully qualified path of the provided Asset instance
    /// </summary>
    /// <param name="asset">The Asset object</param>
    /// <returns>The asset's fully qualified path (string)</returns>
    public string GetAssetPath( Asset asset ) {
        string path = "";

        while( true ) {
            path = asset.name + "/" + path;
            
            if( asset.folderId == 65535 )
                break;
            else {
                if( ! assets.ContainsKey( asset.folderId ) ) {
                    Debug.LogWarning( "FolderId '" + asset.folderId + "' is an unknow asset. " + asset.id + " " + asset.name );
                    break; 
                }
                asset = assets[ asset.folderId ]; // FIXME : some cases of KeyNotFoundException
            }
        }

        return path.TrimEnd('/');
    }


    /// <summary>
    /// Returns the asset object of the provided name.
    /// </summary>
    /// <param name="assetName">The asset name (not path, just the name)</param>
    /// <returns>The asset instance (Asset), or nil</returns>
    public Asset GetAssetByName( string assetName ) {
        foreach( KeyValuePair<uint, Asset> pair in assets ) {
            if( pair.Value.name == assetName )
                return pair.Value;
        }

        return null;
    }


    /// <summary>
    /// Returns all asset instances of the provided type.
    /// </summary>
    /// <param name="type">The asset type (uint)</param>
    /// <param name="includeFolders">Tell wether to include assets that are folders (boolean) [optional default=false]</param>
    /// <returns>The list of the assets instances (List<Asset>)</returns>
    public List<Asset> GetAssetsByType( uint type, bool includeFolders = false ) {
        List<Asset> wantedAssets = new List<Asset>();

        foreach( KeyValuePair<uint, Asset> pair in assets ) {
            if( pair.Value.type == type ) {
                if( pair.Value.isFolder && ! includeFolders )
                    continue;

                wantedAssets.Add( pair.Value );
            }
        }

        return wantedAssets;
    }


    public override string ToString() {
        string project = "Name: " + name + Environment.NewLine;
        project += "Description: " + description + Environment.NewLine;
        project += gameControlsCount + " game controls: " + Environment.NewLine;

        foreach( KeyValuePair<uint, GameControl> control in gameControls )
            project += "    " + control.Value.id + " | " + control.Value.name + Environment.NewLine;

        project += assetsCount + " assets: "+ Environment.NewLine;

        foreach( KeyValuePair<uint, Asset> asset in assets ) {
            project += "        " + asset.Value.id + " | " + asset.Value.name + " | Is Trashed " + asset.Value.isTrashed + " | Is Folder " + asset.Value.isFolder + " | Folder id " + asset.Value.folderId + " | Nb revisions: " + asset.Value.revisionsCount + Environment.NewLine;

            foreach( KeyValuePair<uint, string> revision in asset.Value.revisionNames )
                project += "            " + revision.Key + " | " + revision.Value + Environment.NewLine;
        }

        return project;
    }

} // end of ProjectFileHandler class
