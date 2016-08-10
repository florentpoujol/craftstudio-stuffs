/// <summary>
/// CSScriptEditor.cs
/// 
/// Main script for the CSScript Editor application.
/// This application allows you to edit .cscript files (including public properties) outside CraftStudio.
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
using System.Collections;
using System.Collections.Generic;
using System.IO;
using MiniJSON;

public class CSScriptEditor : MonoBehaviour {

    public class Project {
        public string name = "";
        public List<Script> scripts = new List<Script>();
        public string[] selectionGridTexts = new string[0];
        public int textAreaHeight = 40; // height of the textArea in lines


        public Script GetScriptByPath( string _path ) {
            foreach (Script script in scripts) {
                if (script.path == _path)
                    return script;
            }
            return null;
        }


        public void AddScript( string _path, string _name ) {
            if (_name.Trim() == "")
                _name = CSScriptEditor.GetFileName( _path );

            if (!File.Exists( _path )) {
                CSScriptEditor.Log("Script '"+_path+"' does not exists !");
                return;
            }

            Script script = new Script( _path );
            script.name = _name;
            script.id = scripts.Count;
            
            scripts.Add( script );

            BuildSelectionGridTexts();
            CSScriptEditor.Log("Added script '"+_name+"' with path '"+_path+"' to project '"+name+"'.");
        }


        public void RemoveScript( Script _script ) {
            scripts.Remove( _script );
            BuildSelectionGridTexts();
            CSScriptEditor.Log("Removed script '"+_script.name+"' with path '"+_script.path+"' from project '"+name+"'.");
        }

        
        public void BuildSelectionGridTexts() {
            selectionGridTexts = new string[ scripts.Count ];
            int i = 0;

            foreach (Script script in scripts) {
                string name = script.name;
                if (script.originalContent != script.content)
                    name += " *";
                selectionGridTexts[ i++ ] = name;
            }
        }
    }


    //----------------------------------------------------------------------------------

    public class Script {
        public int id = 0;
        public string name = "";
        public string path = "";
        public CSScript csscript = new CSScript();

        public Project project = new Project();
        
        public string originalContent = null;
        public string content = null;
        public string lastContent = null;

        public string[] contentLines = new string[0]; // content, split into individual lines
        public string lineNumbers = ""; // the content of the lines textarea

        public string originalChunk = ""; // chunk of content that is displayed in the textarea
        public string modifiedChunk = "";

        public Vector2 scrollPosition = new Vector2();
        public Vector2 lastScrollPosition = new Vector2();

        public Script( string _path ) {
            path = _path;
            if (!csscript.Read( path ))
                CSScriptEditor.Log( "ERROR : Failed to read script with path '"+path+"'.");
        }

        public void LoadContent() {
            originalContent = csscript.GetContent();
            content = originalContent;
            lastContent = "";
        }

        public void Save() {
            if (!csscript.Write( path, content ))
                CSScriptEditor.Log( "ERROR : Failed to write script with path '"+path+"'.");

            // reload (to check that tha save has successfully been done)
            CSScriptEditor.Log( "Saved script '"+name+"' with path '"+path+"'." );
            LoadContent();
        }

        public void BuildOriginalChunk() {
            // a textarea can only display about 400+ lines 
            // for files bigger than that, I need to crop the content

            // scrollPositions.y is the height in pixels of the text that is above the top of the text area
            // one line is 15 pixels hight

            // the scroll position tells use the line at which we begin the string
            // line = scroll pos.y / 15 + 1

            originalChunk = "";
            int lineNum = (int)Math.Floor( scrollPosition.y / 15 + 1 );
            int j = 1;
            for (int i = lineNum - 1; i < contentLines.Length; i++) {
                originalChunk += contentLines[i];
                if (j++ < project.textAreaHeight)
                    originalChunk += "\n";
                else
                    break;
            }
        }

        // write .lua file with content and name
        public void WriteLua() {
            string luaPath = path.Replace( ".csscript", name + ".lua" ); // "/2.csscript" > "/2 ScriptName.lua"
            StreamWriter writer = new StreamWriter( luaPath );
            writer.Write( content );
            writer.Flush();
            writer.Close();

            CSScriptEditor.Log( ".lua file created at path '"+luaPath+"'." );
        }
    }


    //----------------------------------------------------------------------------------

    public string mEditorDataPath = "";

    List<Project> projects = new List<Project>();

    Project selectedProject = null;
    Script  selectedScript = null;

    Vector2 projectsScrollPosition = new Vector2();
    Vector2 consoleScrollPosition = new Vector2();

    bool showSettings = true;
    string projectName = "";
    string scriptName = "";
    string scriptPath = "";

    bool showConsole = true;
    static Stack consoleLines = new Stack(); // static because Log() is static (used in CSScript class)

    int selectedScriptId = 0;
    int lastSelectedScriptId = 0;


    //----------------------------------------------------------------------------------

    void Start() {
        if (mEditorDataPath == "" || !Application.isEditor)
            mEditorDataPath = Application.dataPath;
        mEditorDataPath = mEditorDataPath.TrimEnd('/').TrimEnd('\\') + "/EditorData.txt";

        ReadEditorData();
    }

    public static void Log( string text ) {
        consoleLines.Push( text );
        Debug.Log( text );
    }

    void SelectProject( Project _project ) {
        selectedProject = _project;
        projectName = selectedProject.name;
        selectedScript = null;
        Log( "Loaded project '" + selectedProject.name + "'." );
        SaveEditorData();
    }

    void SelectScript( Script _script = null ) {
        selectedScript = _script;
        scriptPath = selectedScript.path;
        scriptName = selectedScript.name;
        if ( selectedScript != null )
            Log( "Loaded script '"+selectedScript.name+"' with path '"+selectedScript.path+"'." );
    }

    public static string GetFileName( string _path ) {
        return _path.Substring( _path.Replace( @"\", "/" ).LastIndexOf( "/" ) + 1 ).Replace( ".csscript", "" );
    }


    //----------------------------------------------------------------------------------

    void ReadEditorData() {
        if (!File.Exists( mEditorDataPath ))
            File.Create( mEditorDataPath ).Close();

        StreamReader reader = new StreamReader( mEditorDataPath );
        string data = reader.ReadToEnd();
        if (data.Trim() == "")
            return;

        Dictionary<string, object> editorData = Json.Deserialize( data ) as Dictionary<string, object>;
        reader.Close();

        showSettings = Convert.ToBoolean( editorData[ "showSettings" ] );
        showConsole = Convert.ToBoolean( editorData[ "showConsole" ] );

        foreach (Dictionary<string, object> projectData in editorData["projects"] as List<object>) {
            Project project = new Project();
            project.name = projectData["name"].ToString();
            if (projectData.ContainsKey( "textAreaHeight" ))
                project.textAreaHeight = Convert.ToInt32( projectData["textAreaHeight"] );

            foreach (Dictionary<string, object> scriptData in projectData["scripts"] as List<object>) {
                Script script = new Script( scriptData["path"].ToString() );
                script.name = scriptData["name"].ToString();
                script.project = project;
                project.scripts.Add( script );
            }
            
            project.BuildSelectionGridTexts();
            projects.Add( project );
        }

        if (projects.Count > 0 && editorData[ "selectedProjectName" ] != null) {
            projectName = editorData[ "selectedProjectName" ].ToString();
            foreach (Project project in projects) {
                if (project.name == projectName) {
                    SelectProject( project );
                    return;
                }
            }
        }
    }

    void SaveEditorData() {
        Dictionary<string, object> editorData = new Dictionary<string, object>();
        editorData.Add( "showSettings", showSettings );
        editorData.Add( "showConsole", showConsole );
        
        if (selectedProject != null)
            editorData.Add( "selectedProjectName", selectedProject.name );
        else
            editorData.Add( "selectedProjectName", "" );
        
        List<object> projectsToSave = new List<object>();
        foreach (Project project in projects) {
            Dictionary<string, object> projectToSave = new Dictionary<string, object>();
            projectToSave.Add( "name", project.name );
            projectToSave.Add( "textAreaHeight", project.textAreaHeight );

            List<object> scriptsToSave = new List<object>();
            foreach (Script script in project.scripts) {
                Dictionary<string, string> scriptToSave = new Dictionary<string, string>();
                scriptToSave.Add( "path", script.path );
                scriptToSave.Add( "name", script.name );
                scriptsToSave.Add( scriptToSave );
            }
            projectToSave.Add( "scripts", scriptsToSave );
            projectsToSave.Add( projectToSave );
        }

        editorData.Add( "projects", projectsToSave );

        // write the temporary file
        string tempPath = mEditorDataPath.Replace( ".txt", "_temp.txt" );

        StreamWriter writer = new StreamWriter( tempPath );
        string text = Json.Serialize( editorData );
        writer.Write( text );
        writer.Close();

        // compare the files length
        StreamReader reader = new StreamReader( mEditorDataPath );
        string oldEditorData = reader.ReadToEnd();
        reader.Close();
        
        reader = new StreamReader( tempPath );
        string newEditorData = reader.ReadToEnd();
        reader.Close();

        if (newEditorData.Length < oldEditorData.Length) {
            // backup the new file
            string backupPath = mEditorDataPath.Replace( ".txt", "_backup.txt" );

            File.Delete( backupPath );
            File.Copy( mEditorDataPath, backupPath );
        }

        File.Delete( mEditorDataPath );
        File.Copy( tempPath, mEditorDataPath );
        File.Delete( tempPath );
    }


    //----------------------------------------------------------------------------------

    void OnGUI() {
        if (selectedProject == null && projects.Count > 0) {
            SelectProject( projects[0] );
        }

        if (selectedProject != null && selectedScript == null && selectedProject.scripts.Count > 0) {
            SelectScript( selectedProject.scripts[0] );
        }


        GUILayout.BeginVertical();

            GUILayout.BeginHorizontal();
                if (GUILayout.Button( "Toggle project settings" )) {
                    showSettings = !showSettings;
                    SaveEditorData();
                }

                if (GUILayout.Button( "Toggle console" )) {
                    showConsole = !showConsole;
                    SaveEditorData();
                }
            GUILayout.EndHorizontal();
            GUILayout.Space( 10 );


            //----------------------------------------------------------------------------------
            // Console

            if (showConsole) {

                if( GUILayout.Button( "Clear console", GUILayout.MaxWidth( 100 ) ) ) {
                    consoleLines.Clear();
                }
                consoleScrollPosition = GUILayout.BeginScrollView( consoleScrollPosition, GUILayout.Height( 75 ) );
                    int id = consoleLines.Count;
                    foreach( string line in consoleLines ) {
                        GUILayout.Label( "#" + id-- + " - " + line );
                    }
                GUILayout.EndScrollView();
                GUILayout.Label( "------------------------------------------------------------------------------------------------------------------------------------------------------" );
                GUILayout.Space(10);
            }


            //----------------------------------------------------------------------------------

            if (showSettings) {          
                //projects
                GUILayout.BeginHorizontal();
                    GUILayout.Label( "Project name : " );
                    projectName = GUILayout.TextField( projectName );
                GUILayout.EndHorizontal();

                GUILayout.BeginHorizontal();
                    if( GUILayout.Button( "Add" ) ) {
                        if( projectName.Trim() == "" ) {
                            Log( "The project name must not be empty !" );
                            return;
                        }

                        Project project = new Project();
                        project.name = projectName;
                        
                        projects.Add( project );
                        SelectProject( project );
                        // saved in SelectProject();
                    }

                    if( 
                        selectedProject != null &&
                        projectName == selectedProject.name &&
                        GUILayout.Button( "Remove" ) 
                    ) {
                        projects.Remove( selectedProject );
                        Log( "Project '"+projectName+"' removed." );
                        
                        if ( projects.Count > 0 )
                            SelectProject( projects[0] );
                        else {
                            selectedProject = null;
                            projectName = "";
                            SaveEditorData();
                            return;
                        }
                    }
                GUILayout.EndHorizontal();

                if (selectedProject != null) {
                    GUILayout.BeginHorizontal();
                        GUILayout.Label( "Editor height (in lines) : " );
                        selectedProject.textAreaHeight = Convert.ToInt32( GUILayout.TextField( selectedProject.textAreaHeight.ToString() ) );

                        if (selectedProject.textAreaHeight <= 0)
                            selectedProject.textAreaHeight = 40;
                        else if (selectedProject.textAreaHeight > 200)
                            selectedProject.textAreaHeight = 40;
                        
                        if( GUILayout.Button( "Save" ) ) {
                            SaveEditorData();
                            Log( "Saved editor height." );
                        }
                    GUILayout.EndHorizontal();
                }
                
                GUILayout.Space(20);
                GUILayout.Label ("Your projects : " );

                projectsScrollPosition = GUILayout.BeginScrollView( projectsScrollPosition, GUILayout.Height( 75 ) );
                    foreach( Project project in projects ) {
                        if( GUILayout.Button( project.name ) )
                            SelectProject( project );
                    }
                GUILayout.EndScrollView();

                // scripts
                if (selectedProject != null) {
                    GUILayout.Space(10);
              
                    GUILayout.BeginHorizontal();
                        GUILayout.Label( "Script name : " );
                        scriptName = GUILayout.TextField( scriptName );
                    GUILayout.EndHorizontal();
                    GUILayout.BeginHorizontal();
                        GUILayout.Label( "Script path : " );
                        scriptPath = GUILayout.TextField( scriptPath );
                    GUILayout.EndHorizontal();
                    
                    GUILayout.BeginHorizontal();
                        if (GUILayout.Button( "Add" )) {
                            scriptPath = scriptPath.Replace( @"\", "/" );

                            if (scriptPath.Trim() == "" || !scriptPath.Contains( "/" ) || !scriptPath.Contains( ".csscript" )) {
                                Log( "Wrong script path !");
                                return;
                            }

                            if (selectedProject.GetScriptByPath( scriptPath ) == null) 
                            {
                                selectedProject.AddScript( scriptPath, scriptName );
                                SaveEditorData();
                            }
                            else 
                                Log( "A script with this path already exists in the project." );
                        }

                        if (selectedScript != null && GUILayout.Button( "Remove" )) {
                            selectedProject.RemoveScript( selectedScript );
                            selectedScript = null;
                            scriptName = "";
                            scriptPath = "";
                            SaveEditorData();
                        }
                    GUILayout.EndHorizontal();

                    GUILayout.Label ("Project's scripts :" );

                    foreach (Script script in selectedProject.scripts) {
                        // Key = path, Value = name
                        GUILayout.BeginHorizontal();
                            if ( GUILayout.Button( "Path : '"+script.path + "' | name : '" + script.name+"'" ) ) {
                                SelectScript( script );
                            }


                            if ( selectedScript == script && GUILayout.Button( "Write .lua" ) ) {
                                selectedScript.WriteLua();
                            }
                        GUILayout.EndHorizontal();
                    }
                }


                GUILayout.Label( "------------------------------------------------------------------------------------------------------------------------------------------------------" );
                GUILayout.Space(10);
            } // end if (showSettings)


            //----------------------------------------------------------------------------------
            // Script textArea

            if (selectedProject == null && projects.Count > 0) {
                SelectProject( projects[0] );
            }

            if (selectedScript == null && selectedProject != null && selectedProject.scripts.Count > 0)
                SelectScript( selectedProject.scripts[0] );

            if (selectedProject != null && selectedScript != null)
                DrawScriptEditor();

        GUILayout.EndVertical();
    } // end of GUI() method


    void DrawScriptEditor() {
        GUILayout.BeginVertical();
            // selection grid (with script names)
            lastSelectedScriptId = selectedScriptId;
            selectedScriptId = GUILayout.SelectionGrid( selectedScriptId, selectedProject.selectionGridTexts, selectedProject.selectionGridTexts.Length, GUILayout.ExpandWidth(true) );

            // load new script
            if (selectedScriptId != lastSelectedScriptId) {
                if (selectedScriptId < selectedProject.scripts.Count) {
                    SelectScript( selectedProject.scripts[selectedScriptId] );
                }
                else if (selectedProject.scripts.Count > 0)
                    SelectScript( selectedProject.scripts[0] );
                else { // should not happend
                    SelectScript( null );
                    return;
                }    
            }

            if (selectedScript.content == null) 
                selectedScript.LoadContent();

            string saveButtonText = "Save";
            if ( selectedScript.originalContent != selectedScript.content) {
                saveButtonText += " *";
            }

            if (GUILayout.Button( saveButtonText, GUILayout.MinHeight( 40 ) )) {
                selectedScript.Save();
                selectedProject.BuildSelectionGridTexts();
            }          

            if (selectedScript.originalChunk == "" || selectedScript.originalChunk != selectedScript.modifiedChunk) {
                // the script has been modified the last frame
                selectedScript.contentLines = selectedScript.content.Split('\n');
                int length = selectedScript.contentLines.Length;
                //if (length < selectedProject.textAreaHeight) length = selectedProject.textAreaHeight;

                selectedScript.lineNumbers = "";
                for (int i=1; i <= length; i++) {
                    selectedScript.lineNumbers += i;
                    if (i != length)
                        selectedScript.lineNumbers += "\n"; // don't has it for the last line
                }

                selectedScript.BuildOriginalChunk();
            }
            else if (selectedScript.scrollPosition != selectedScript.lastScrollPosition)
                selectedScript.BuildOriginalChunk();

            
            GUILayout.BeginHorizontal();
                selectedScript.lastScrollPosition = selectedScript.scrollPosition;
                selectedScript.scrollPosition = GUILayout.BeginScrollView( selectedScript.scrollPosition, GUILayout.Width(60), GUILayout.Height(selectedProject.textAreaHeight * 15 +15 ));
                    // GUILayout.TextArea( selectedScript.lineNumbers );
                    GUILayout.Label( selectedScript.lineNumbers );
                GUILayout.EndScrollView();

                selectedScript.modifiedChunk = GUILayout.TextArea( selectedScript.originalChunk, GUILayout.MaxWidth( 750 ) );
            GUILayout.EndHorizontal();


            if (selectedScript.modifiedChunk != selectedScript.originalChunk && selectedScript.originalChunk != "") { // selectedScript.originalChunk != "" prevent an "old value is the empty string" error
                selectedScript.lastContent = selectedScript.content;
                selectedScript.content = selectedScript.content.Replace( selectedScript.originalChunk, selectedScript.modifiedChunk );
                selectedProject.BuildSelectionGridTexts();
            }


            if (GUILayout.Button( saveButtonText, GUILayout.MinHeight( 40 ) )) {
                selectedScript.Save();
                selectedProject.BuildSelectionGridTexts();
            }

        GUILayout.EndVertical();
    }
}
