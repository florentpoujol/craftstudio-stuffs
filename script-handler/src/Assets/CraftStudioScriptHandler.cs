/// <summary>
/// CraftStudioScriptHandler.cs
/// Main script for the CraftStudio Script Handler application.
///
/// This app can convert CraftStudio's Script assets (.csscript) to regular Lua scripts (.lua) and vice-versa.
/// The app can read a CraftStudio project and create a .lua version of all of the project's scripts.  
/// It can also read .lua scripts and write the corresponding Script asset in a CraftStudio project.
/// The script's public properties may be modified from the `.lua` version.
///
/// Version: 1.0
///
/// Copyright © 2013-2014 Florent POUJOL
/// http://florentpoujol.fr
///
/// Permission is hereby granted, free of charge, to any person obtaining a
/// copy of this software and associated documentation files (the "Software"),
/// to deal in the Software without restriction, including without limitation
/// the rights to use, copy, modify, merge, publish, distribute, sublicense,
/// and/or sell copies of the Software, and to permit persons to whom the
/// Software is furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
/// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
/// DEALINGS IN THE SOFTWARE.
/// </summary>

using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using MiniJSON;


public class Project {
    public string path = "";
    public string name = "";
}


public class CraftStudioScriptHandler : MonoBehaviour {
    public static CraftStudioScriptHandler instance;
    public Stack consoleLines = new Stack();

    Project selectedCSProject = null;
    Project selectedLuaProject = null;

    List<Project> CSProjects = new List<Project>();
    List<Project> LuaProjects = new List<Project>();
    
    ProjectFileHandler projectFileHandler;


    //----------------------------------------------------------------------------------

    void Start() {
        instance = this;
        ReadProjectsInfoFile();
    }

    void Log( string text ) {
        consoleLines.Push( text );
        Debug.Log( text );
    }

    void ReadProject() {
        projectFileHandler = new ProjectFileHandler( selectedCSProject.path );
        projectFileHandler.Read();
    }


    //----------------------------------------------------------------------------------
    // read and wite the "projectsInfo.txt" file containing the projects data as Json

    void ReadProjectsInfoFile() {
        StreamReader reader = new StreamReader( Application.dataPath + "/projectsInfo.txt" );
        Dictionary<string, object> projectsInfo = Json.Deserialize( reader.ReadToEnd() ) as Dictionary<string, object>;
        
        foreach( Dictionary<string, object> project in projectsInfo["CSProjects"] as List<object> ) {
            Project p = new Project();
            p.path = project["path"].ToString();
            p.name = project["name"].ToString();
            CSProjects.Add( p );
        }

        
        foreach( Dictionary<string, object> project in projectsInfo["LuaProjects"] as List<object> ) {
            Project p = new Project();
            p.path = project["path"].ToString();
            p.name = project["name"].ToString();
            LuaProjects.Add( p );
        }

        Log( "File projectsInfo.txt was successfully read" );
    }

    void SaveProjectsInfoFile() {
        Dictionary<string, List<Dictionary<string, string>>> projectsInfo = new Dictionary<string, List<Dictionary<string, string>>>();
        projectsInfo.Add( "CSProjects", new List<Dictionary<string, string>>() );
        projectsInfo.Add( "LuaProjects", new List<Dictionary<string, string>>() );

        foreach( Project project in CSProjects ) {
            Dictionary<string, string> _project = new Dictionary<string, string>();
            _project.Add( "path", project.path );
            _project.Add( "name", project.name );

            projectsInfo["CSProjects"].Add( _project );
        }
        foreach( Project project in LuaProjects ) {
            Dictionary<string, string> _project = new Dictionary<string, string>();
            _project.Add( "path", project.path );
            _project.Add( "name", project.name );

            projectsInfo["LuaProjects"].Add( _project );
        }

        string text = Json.Serialize( projectsInfo );
        //Debug.Log( text );

        // actually write the file
        StreamWriter writer = new StreamWriter( Application.dataPath + "/projectsInfo.txt" );
        writer.Write( text );
        writer.Close();
    }

    //----------------------------------------------------------------------------------

    /// <summary>
    /// Write .lua scripts at path 'selectedLuaProject.path'
    /// with data from the scripts asset of the CraftStudio project at path 'selectedCSProject.path'
    /// </summary>
    void WriteLuaFromCSScript() {
        if( projectFileHandler == null || ! projectFileHandler.isRead ) {
            Log( "ERROR : The CraftStudio project is not set or wasn't sucessfully read." );
            return;
        }

        Log( "Reading CS project with name '" + selectedCSProject.name + "' and writing Lua project with name '" + selectedLuaProject.name + "' at path '" + selectedLuaProject.path + "'" );

        // read .csscript
        List<Asset> assets = projectFileHandler.GetAssetsByType( 7 );

        foreach( Asset asset in assets ) {
            ScriptFileHandler script = new ScriptFileHandler( asset );
            script.ReadRevisionFile( "Current" );
            
            // write .lua
            string luaPath = selectedLuaProject.path;

            string scriptFolders = script.GetPath(); // asset path in CraftStudio
            if( scriptFolders.Contains( "/" ) ) // script is inside at least one folder
                luaPath += "/" + scriptFolders.Substring( 0, scriptFolders.LastIndexOf( "/" ) );

            if( ! Directory.Exists( luaPath ) )
                Directory.CreateDirectory( luaPath );

            luaPath += "/" + script.name + ".lua";
            StreamWriter writer = new StreamWriter( luaPath );
            string code = script.GetLuaStringFromRevision( "Current" );
            writer.Write( code );
            writer.Close();

            Log( "Lua script '" + script.name + "' was written at path '" + luaPath + "' from script asset with id '" + script.id + "'" );
        }
    }


    /// <summary>
    /// Write Script assets in the CraftStudio project at path 'selectedCSProject.path'
    /// with data from the .lua scripts at path 'selectedLuaProject.path'
    /// </summary>
    void WriteCSScriptFromLua() {
        if( projectFileHandler == null || ! projectFileHandler.isRead ) {
            Log( "ERROR : The CraftStudio project is not set or wasn't sucessfully read." );
            return;
        }

        Log( "Reading Lua project with name '" + selectedLuaProject.name + "' at path '" + selectedLuaProject.path + "' and writing scripts in CraftStudio project with name '" + selectedCSProject.name + "'" );

        string[] luaPaths = Directory.GetFiles( selectedLuaProject.path, "*.lua", SearchOption.AllDirectories );
        
        List<Asset> projectScripts = projectFileHandler.GetAssetsByType( 7 );

        foreach( string tempPath in luaPaths ) {
            string luaScriptPath = tempPath.Replace( @"\", "/" );
            string luaScriptFolders = luaScriptPath.Replace( selectedLuaProject.path + "/", "" ).Replace( ".lua", "" ); // luaScriptFolders is now just the folders + the file name
            string fileName = luaScriptFolders.Substring( luaScriptFolders.LastIndexOf( "/" ) + 1 );
            
            bool fileWritten = false;
            // copy the file only if it is know
            foreach( Asset asset in projectScripts ) {
                if( asset.isTrashed )
                    continue;
                
                string assetFolders = asset.GetPath();
                
                if( 
                    ( matchScriptsByName == 0 && assetFolders == luaScriptFolders ) ||
                    ( matchScriptsByName == 1 && asset.name == fileName ) 
                ) {
                    
                    ScriptFileHandler script = new ScriptFileHandler( asset );
                    script.ReadRevisionFile( "Current" ); // read the revision to store the head of the script (the first 8 octets that I don't know what they are)

                    StreamReader reader = new StreamReader( luaScriptPath );
                    script.WriteRevisionFromLuaString( reader.ReadToEnd(), "Current" );
                    reader.Close();
                    
                    fileWritten = true;
                    if( matchScriptsByName == 1 )
                        Log( "Script asset with id '" + asset.id + "' and path '" + assetFolders + "' was successfully written from .lua script at path '" + luaScriptFolders + "'" );
                    else
                        Log( "Script asset with id '" + asset.id + "' and path '" + assetFolders + "' was successfully written." );

                    break;
                }
            }

            luaScriptPath = luaScriptPath.Replace( selectedLuaProject.path, "" );
            if( ! fileWritten )
                Log( "WARNING : .lua script at path " + luaScriptPath + "' does not seems to match any script asset in the project." );
        }
    }


    //----------------------------------------------------------------------------------
    // GUI stuffs

    Vector2 csProjectsScrollPosition = new Vector2();
    string csProjectPath = "";
    string csProjectName = "";

    Vector2 luaProjectsScrollPosition = new Vector2();
    string luaProjectPath = "";
    string luaProjectName = "";
    
    Vector2 consoleScrollPosition = new Vector2();

    int matchScriptsByName = 0; // 0 = false, 1 = true
    //string[] names = new string[]["match by path", "math by name"]

    void OnGUI() {
        
        GUILayout.BeginHorizontal( GUILayout.MaxWidth( 1000 ) );
            // CS projects

            GUILayout.BeginVertical( GUILayout.MinWidth( 499 ), GUILayout.MaxWidth( 500 ) );
                GUILayout.Label( "CRAFTSTUDIO" );
                GUILayout.Space( 10 );

                // project path
                GUILayout.Label( "Full project's path (with guid) : " );
                csProjectPath = GUILayout.TextField( csProjectPath, GUILayout.MaxWidth( 500 ) );
                
                //project name
                GUILayout.BeginHorizontal();
                    GUILayout.Label( "Project's name : " );
                    csProjectName = GUILayout.TextField( csProjectName );
                GUILayout.EndHorizontal();

                GUILayout.BeginHorizontal();
                    if( GUILayout.Button( "Add new" ) ) {
                        if( csProjectPath.Trim() == "" || csProjectName.Trim() == "" ) {
                            Log( "ERROR : Either the path or name is empty" );
                            return;
                        }

                        selectedCSProject = new Project();
                        CSProjects.Add( selectedCSProject );
                        
                        selectedCSProject.path = csProjectPath.Replace( @"\", "/" );
                        selectedCSProject.name = csProjectName;
                        
                        SaveProjectsInfoFile();

                        ReadProject();
                        if( projectFileHandler.isRead )
                            Log( "Added and saved new CS project" );
                    }

                    if( GUILayout.Button( "Save modifs" ) ) {
                        if( csProjectPath.Trim() == "" || csProjectName.Trim() == "" ) {
                            Log( "ERROR : Either the path or name is empty" );
                            return;
                        }

                        if( selectedCSProject == null ) {
                            selectedCSProject = new Project();
                            CSProjects.Add( selectedCSProject );
                        }

                        selectedCSProject.path = csProjectPath.Replace( @"\", "/" );
                        selectedCSProject.name = csProjectName;
                        
                        SaveProjectsInfoFile();

                        ReadProject();
                        if( projectFileHandler.isRead )
                            Log( "Modifications saved" );
                    }

                    if( GUILayout.Button( "Delete current" ) ) {
                        if( selectedCSProject != null )
                            CSProjects.Remove( selectedCSProject );

                        selectedCSProject = null;
                        csProjectPath = "";
                        csProjectName = "";

                        SaveProjectsInfoFile();
                        Log( "CS project deleted" );
                    }
                GUILayout.EndHorizontal();
                
                GUILayout.Space( 20 );

                csProjectsScrollPosition = GUILayout.BeginScrollView( csProjectsScrollPosition, GUILayout.MaxHeight( 150 ) );
                    GUI.skin.button.alignment = TextAnchor.MiddleLeft;
                    foreach( Project project in CSProjects ) {
                        //Debug.Log( project.name + " " + project.path);
                        if( GUILayout.Button( project.name + "  |  " + project.path ) ) {
                            selectedCSProject = project;
                            csProjectPath = selectedCSProject.path;
                            csProjectName = selectedCSProject.name;

                            ReadProject();
                            if( projectFileHandler.isRead )
                                Log( "Selected CS project with name '" + project.name + "'" );
                        }
                    }
                    GUI.skin.button.alignment = TextAnchor.MiddleCenter;
                GUILayout.EndScrollView();

                GUILayout.Space( 20 );

                if( GUILayout.Button( "Write .lua scripts from selected CraftStudio project. (.csscript > .lua) >" ) ) {
                    if( selectedCSProject == null || selectedLuaProject == null ) {
                        Log( "ERROR : your need to select a CS project and a Lua project." );
                        return;
                    }

                    WriteLuaFromCSScript();
                }

            GUILayout.EndVertical();


            // Lua projects

            GUILayout.BeginVertical( GUILayout.MinWidth( 499 ), GUILayout.MaxWidth( 500 ) );
                GUILayout.Label( "LUA" );
                GUILayout.Space( 10 );

                // project path
                GUILayout.Label( "Project's path : " );
                luaProjectPath = GUILayout.TextField( luaProjectPath, GUILayout.MaxWidth( 500 ) );
                
                //project name
                GUILayout.BeginHorizontal();
                    GUILayout.Label( "Project's name : " );
                    luaProjectName = GUILayout.TextField( luaProjectName );
                GUILayout.EndHorizontal();

                GUILayout.BeginHorizontal();
                    if( GUILayout.Button( "Add new" ) ) {
                        if( luaProjectPath.Trim() == "" || luaProjectName.Trim() == "" ) {
                            Log( "ERROR : Either the path or name is empty" );
                            return;
                        }

                        selectedLuaProject = new Project();
                        LuaProjects.Add( selectedLuaProject );
                        
                        selectedLuaProject.path = luaProjectPath.Replace( @"\", "/" );
                        selectedLuaProject.name = luaProjectName;
                        SaveProjectsInfoFile();

                        Log( "Added and saved new Lua project" );
                    }

                    if( GUILayout.Button( "Save modifs" ) ) {
                        if( luaProjectPath.Trim() == "" || luaProjectName.Trim() == "" ) {
                            Log( "ERROR : Either the path or name is empty" );
                            return;
                        }

                        if( selectedLuaProject == null ) {
                            selectedLuaProject = new Project();
                            LuaProjects.Add( selectedLuaProject );
                        }
                        
                        selectedLuaProject.path = luaProjectPath.Replace( @"\", "/" );
                        selectedLuaProject.name = luaProjectName;
                        
                        SaveProjectsInfoFile();
                        Log( "Modifications saved" );
                    }

                    if( GUILayout.Button( "Delete current" ) ) {
                        if( selectedLuaProject != null )
                            LuaProjects.Remove( selectedLuaProject );

                        selectedLuaProject = null;
                        luaProjectPath = "";
                        luaProjectName = "";

                        SaveProjectsInfoFile();
                        Log( "Lua project deleted" );
                    }
                GUILayout.EndHorizontal();
                
                GUILayout.Space( 20 );

                luaProjectsScrollPosition = GUILayout.BeginScrollView( luaProjectsScrollPosition, GUILayout.MaxHeight( 150 ) );
                    GUI.skin.button.alignment = TextAnchor.MiddleLeft;
                    foreach( Project project in LuaProjects ) {
                        //Debug.Log( project.name + " " + project.path);
                        if( GUILayout.Button( project.name + "  |  " + project.path ) ) {
                            selectedLuaProject = project;
                            luaProjectPath = project.path;
                            luaProjectName = project.name;

                            Log( "Selected Lua project with name '" + project.name + "'" );
                        }
                    }
                    GUI.skin.button.alignment = TextAnchor.MiddleCenter;
                GUILayout.EndScrollView();

                GUILayout.Space( 20 );

                GUILayout.Label( "Match .lua scripts with Script assets by :");
                matchScriptsByName = GUILayout.SelectionGrid( matchScriptsByName, new string[] {"path (\"Folder/File.lua\" will only write existing \"Folder/File\" asset)", "name (\"Whatever/File.lua\" will write the first \"File\" asset found)"}, 1, "toggle");

                GUILayout.Space( 20 );

                if( GUILayout.Button( "< Write CraftStudio project from selected Lua project. (.lua > .csscript)" ) ) {
                    if( selectedCSProject == null || selectedLuaProject == null ) {
                        Log( "ERROR : your need to select a CS project and a Lua project." );
                        return;
                    }

                    WriteCSScriptFromLua();
                }

            GUILayout.EndVertical();
        GUILayout.EndHorizontal();

        GUILayout.Space( 40 );

        GUILayout.Label( "Console --------------------------------------------------------------------------" );
        if( GUILayout.Button( "Clear console", GUILayout.MaxWidth( 100 ) ) ) {
            consoleLines.Clear();
        }
        consoleScrollPosition = GUILayout.BeginScrollView( consoleScrollPosition, GUILayout.MaxHeight( 200 ) );
            int id = consoleLines.Count;
            foreach( string line in consoleLines ) {
                GUILayout.Label( "#" + id-- + " - " + line );
            }
        GUILayout.EndScrollView();
        GUILayout.Label( "----------------------------------------------------------------------------------" );
    } // end of GUI() method  
} // end of CraftStudioScriptHandler class
