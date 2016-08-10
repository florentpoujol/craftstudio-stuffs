/// <summary>
/// Common.cs
/// Part of the CraftStudio Script Handler application
///
/// Copyright © 2013-2014 Florent POUJOL
/// http://florentpoujol.fr
/// </summary>

using System.Collections.Generic;

public enum AssetType { // not used
    UnKnow = -1,
    Model = 0,
    Scene = 2,
    Animation = 6,
    Script = 7,
    Sound = 8,
    Font = 9
}


/// <summary>
/// Generic class for CraftStudio's assets.
/// Is parent of asset-specific classes.
/// </summary>
public class Asset {
    public ProjectFileHandler projectHandler;
    public string path = "";

    public uint id;
    public string name = "";
    public uint type;

    public uint nextRevisionId;
    public uint revisionsCount = 0;
    public Dictionary<uint, string> revisionNames = new Dictionary<uint, string>();

    public bool isFolder = false;
    public uint folderId;
    public bool isTrashed = false;

    public string GetRevisionNameFromPath( string p_path ) {
        p_path = p_path.Replace( @"\", "/" );
        string fileName = p_path.Substring( p_path.LastIndexOf( "/" ) + 1 ); // ie : 02.csscript    Currrent.csscript
        string revision = fileName.Substring( 0, fileName.LastIndexOf( '.' ) );
        return revision;
    }

    public string GetPath() {
        return projectHandler.GetAssetPath( this );
    }
}
