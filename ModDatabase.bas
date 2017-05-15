Attribute VB_Name = "ModDatabase"
'===============================================================
' Module ModDatabase
' v0,0 - Initial Version
' v0,1 - Improved message box
' v0,2 - Added GetDBVer function
' v0,32 - Asset Import functionality
'---------------------------------------------------------------
' Date - 15 May 17
'===============================================================

Option Explicit

Private Const StrMODULE As String = "ModDatabase"

Public DB As DAO.Database
Public MyQueryDef As DAO.QueryDef

' ===============================================================
' SQLQuery
' Queries database with given SQL script
' ---------------------------------------------------------------
Public Function SQLQuery(SQL As String) As Recordset
    Dim RstResults As Recordset
    
    Const StrPROCEDURE As String = "SQLQuery()"

    On Error GoTo ErrorHandler
      
Restart:
    Application.StatusBar = ""

    If DB Is Nothing Then
        Err.Raise NO_DATABASE_FOUND, Description:="Unable to connect to database"
    Else
        If ModErrorHandling.FaultCount1008 > 0 Then ModErrorHandling.FaultCount1008 = 0
    
        Set RstResults = DB.OpenRecordset(SQL, dbOpenDynaset)
        Set SQLQuery = RstResults
    End If
    
    Set RstResults = Nothing
    
Exit Function

ErrorExit:

    Set RstResults = Nothing

    Set SQLQuery = Nothing
    Terminate

Exit Function

ErrorHandler:
    
    If Err.Number >= 1000 And Err.Number <= 1500 Then
        If CustomErrorHandler(Err.Number) Then
            If Not Initialise Then Err.Raise HANDLED_ERROR
            Resume Restart
        Else
            Err.Raise HANDLED_ERROR
        End If
    End If

    If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' DBConnect
' Provides path to database
' ---------------------------------------------------------------
Public Function DBConnect() As Boolean
    Const StrPROCEDURE As String = "DBConnect()"

    On Error GoTo ErrorHandler

    DB_PATH = ShtSettings.Range("DBPath")
    
    If DB_PATH = "" Then
        MsgBox ("No database selected")
        ModDatabase.SelectDB
    Else
        Set DB = OpenDatabase(DB_PATH)
    End If
    DBConnect = True

Exit Function

ErrorExit:

    DBConnect = False

Exit Function

ErrorHandler:

If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function


' ===============================================================
' DBTerminate
' Disconnects and closes down DB connection
' ---------------------------------------------------------------
Public Function DBTerminate() As Boolean
    Const StrPROCEDURE As String = "DBTerminate()"

    On Error GoTo ErrorHandler

    If Not DB Is Nothing Then DB.Close
    Set DB = Nothing

    DBTerminate = True

Exit Function

ErrorExit:

    DBTerminate = False

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' SelectDB
' Selects DB to connect to
' ---------------------------------------------------------------
Public Function SelectDB() As Boolean
    Const StrPROCEDURE As String = "SelectDB()"

    On Error GoTo ErrorHandler
    Dim DlgOpen As FileDialog
    Dim FileLoc As String
    Dim NoFiles As Integer
    Dim i As Integer
    
    On Error GoTo ErrorHandler
    
    'open files
    Set DlgOpen = Application.FileDialog(msoFileDialogOpen)
    
     With DlgOpen
        .Filters.Clear
        .Filters.Add "Access Files (*.accdb)", "*.accdb"
        .AllowMultiSelect = False
        .Title = "Connect to Database"
        .Show
    End With
    
    'get no files selected
    NoFiles = DlgOpen.SelectedItems.Count
    
    'exit if no files selected
    If NoFiles = 0 Then
        MsgBox "There was no database selected", vbOKOnly + vbExclamation, "No Files"
        SelectDB = True
        Exit Function
    End If
  
    'add files to array
    For i = 1 To NoFiles
        FileLoc = DlgOpen.SelectedItems(i)
    Next
    
    DB_PATH = FileLoc
    
    Set DlgOpen = Nothing

    SelectDB = True

Exit Function

ErrorExit:

    Set DlgOpen = Nothing
    SelectDB = False

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' ImportAssetFile
' Imports the Asset file into the database
' ---------------------------------------------------------------
Private Sub ImportAssetFile()
    Dim DlgOpen As FileDialog
    Dim LineInputString As String
    Dim AssetData() As String
    Dim FormValidation As Integer
    Dim AssetFileLoc As String
    Dim Asset As ClsAsset
    Dim Assets As ClsAssets
    Dim NoFiles As Integer
    Dim AssetFile As Integer
    Dim RstAssets As Recordset
    Dim i As Integer
    
    Const StrPROCEDURE As String = "ImportAssetFile()"

    On Error GoTo ErrorHandler
    Set DlgOpen = Application.FileDialog(msoFileDialogOpen)
    Set Assets = New ClsAssets
    
     With DlgOpen
        .Filters.Clear
        .Filters.Add "CSV Files (*.csv)", "*.csv"
        .AllowMultiSelect = False
        .Title = "Select Spreadsheet of Doom"
'        .Show
    End With
    
    'get no files selected
    NoFiles = DlgOpen.SelectedItems.Count
    
    'exit if no files selected
'    If NoFiles = 0 Then Err.Raise NO_FILE_SELECTED

'    AssetFileLoc = DlgOpen.SelectedItems(1)
    AssetFileLoc = "\\lincsfire.lincolnshire.gov.uk\folderredir$\Documents\julian.turner\Documents\RDS Project\Stores IT Project\Data\tblasset.csv"
    AssetFile = FreeFile()
    
    If Dir(AssetFileLoc) = "" Then Err.Raise NO_FILE_SELECTED
    
    'get Asset Recordset
    Set RstAssets = SQLQuery("TblAsset")
    
    Open AssetFileLoc For Input As AssetFile
    
    While Not EOF(AssetFile)
        Line Input #AssetFile, LineInputString
        AssetData = Split(LineInputString, ",")
        i = i + 1
        
        Debug.Print "Starting Line: " & i
        
        If i <> 1 Then
        
            FormValidation = ParseAsset(AssetData, i)
            
            Select Case FormValidation
                Case 999
                    Err.Raise HANDLED_ERROR
                Case Is > 0
                    Err.Raise IMPORT_ERROR
            End Select
            
            Debug.Print "Validated!"
            
            Set Asset = New ClsAsset
    
            Set Asset = BuildAsset(AssetData)
            
            Assets.AddItem Asset
            If Err.Number <> 0 Then Err.Raise IMPORT_ERROR
            
            Debug.Print "Asset Added!"
        End If
    Wend
    Close #AssetFile

    Stop
    
    'check whether there are more assets to add than records to delete, or vice versa
    If RstAssets.RecordCount > Assets.Count Then
    
        With RstAssets
            .MoveFirst
            For i = 1 To .RecordCount
                .Delete
                Assets(i).DBSave
                .MoveNext
            Next
            
            For i = .RecordCount + 1 To Assets.Count
                Assets(i).DBSave
            Next
            
        End With
    Else
        With RstAssets
            .MoveFirst
            For i = 1 To Assets.Count
                .Delete
                Assets(i).DBSave
                .MoveNext
            Next
            
            For i = Assets.Count + 1 To .RecordCount
                .Delete
                .MoveNext
            Next

        End With
    End If


GracefulExit:

    Set DlgOpen = Nothing
    Set Assets = Nothing
    Set RstAssets = Nothing

Exit Sub

ErrorExit:

'    ***CleanUpCode***
    Set DlgOpen = Nothing
    Set Assets = Nothing
    Set RstAssets = Nothing
Exit Sub

ErrorHandler:

    If Err.Number >= 1000 And Err.Number <= 1500 Then
        
        If Err.Number = IMPORT_ERROR Then
            Select Case FormValidation
                Case Is < 25
                    MsgBox "There has been an error importing the data on line " & i & ", Field " & FormValidation + 1, vbExclamation, APP_NAME
                Case Is = 25
                    MsgBox "There is an error with the number of columns on line " _
                            & i & " This is commonly caused by commas not encase in Quote marks", vbExclamation, APP_NAME
            End Select
            
            Stop
            Resume
        End If
        
        If CustomErrorHandler(Err.Number) Then
            GoTo GracefulExit
        End If
    End If
    
    If CentralErrorHandler(StrMODULE, StrPROCEDURE, , True) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Sub

' ===============================================================
' UpdateDBScript
' Script to update DB
' ---------------------------------------------------------------
Public Sub UpdateDBScript()
    Dim TableDef As DAO.TableDef
    Dim Ind As DAO.Index
    Dim RstTable As Recordset
    Dim i As Integer
    
    Dim Fld As DAO.Field
    
    Initialise
    
    Set TableDef = DB.CreateTableDef("TblDBVersion")
    
    With TableDef
        
        Set Fld = .CreateField("Version", dbText)

        .Fields.Append Fld
        DB.TableDefs.Append TableDef
        
    End With
        
    Set RstTable = SQLQuery("TblDBVersion")
    
    With RstTable
        .AddNew
        .Fields(0) = "v0,31"
        .Update
    End With
    
    Set TableDef = DB.TableDefs("TblAsset")
    
    With TableDef
        
        For Each Ind In .Indexes
            Debug.Print Ind.Name
        
        Next
        
        With .Indexes
            .Delete "PrimaryKey"
            .Delete "ID"
        End With
        .Fields.Delete "ID"
        
        
    End With
    
    Set RstTable = Nothing
    Set TableDef = Nothing
    Set Fld = Nothing

End Sub

' ===============================================================
' ParseAsset
' Checks asset data quality
' ---------------------------------------------------------------
Private Function ParseAsset(AssetData() As String, LineNo As Integer) As Integer
    Dim i As Integer
    Dim TestValue As String
    Dim TestString() As String
    
    Const StrPROCEDURE As String = "ParseAsset()"
    
    On Error GoTo ErrorHandler
    
    If UBound(AssetData) < 25 Then
        i = 25
        Err.Raise IMPORT_ERROR
    End If
    
    For i = 0 To 25
    
        TestValue = AssetData(i)
        
        'generic tests first
        If InStr(TestValue, "'") <> 0 Then Err.Raise IMPORT_ERROR

'** test for too many commas

        Select Case i
            Case Is = 0
        
'** add check to ensure unique numeric key"
            
'** add check to ensure that asset description matches asset no

'** ensure category 1 is not NULL and other fields too
            
            Case Is = 1
                If Not IsNumeric(TestValue) Then Err.Raise IMPORT_ERROR
                If TestValue < 0 Or TestValue > 2 Then Err.Raise IMPORT_ERROR
        
            Case Is = 4
                If IsNumeric(TestValue) Then
                If TestValue < 0 Then Err.Raise IMPORT_ERROR
                Else
                    If TestValue <> "" Then Err.Raise IMPORT_ERROR
                End If
    
            Case Is = 11
                If Not IsNumeric(TestValue) Then Err.Raise IMPORT_ERROR
                If TestValue < 0 Then Err.Raise IMPORT_ERROR
            
            Case Is = 12
                If Not IsNumeric(TestValue) Then Err.Raise IMPORT_ERROR
                If TestValue < 0 Then Err.Raise IMPORT_ERROR
            
            Case Is = 13
                If Not IsNumeric(TestValue) Then Err.Raise IMPORT_ERROR
                If TestValue < 0 Then Err.Raise IMPORT_ERROR
            
            Case Is = 16
                
                If Len(TestValue) <> 13 Then Err.Raise IMPORT_ERROR
                
                On Error GoTo ValidationError
                
                TestString = Split(TestValue, ":")
                
                If TestString(0) <> "0" And TestString(0) <> "1" Then Err.Raise IMPORT_ERROR
                If TestString(1) <> "0" And TestString(1) <> "1" Then Err.Raise IMPORT_ERROR
                If TestString(2) <> "0" And TestString(2) <> "1" Then Err.Raise IMPORT_ERROR
                If TestString(3) <> "0" And TestString(3) <> "1" Then Err.Raise IMPORT_ERROR
                If TestString(4) <> "0" And TestString(4) <> "1" Then Err.Raise IMPORT_ERROR
                If TestString(5) <> "0" And TestString(5) <> "1" Then Err.Raise IMPORT_ERROR
                If TestString(6) <> "0" And TestString(6) <> "1" Then Err.Raise IMPORT_ERROR
    
                On Error GoTo ErrorHandler
    
            Case Is = 22
                If TestValue <> "" Then
                If Not IsNumeric(TestValue) Then Err.Raise IMPORT_ERROR
                If TestValue < 0 Then Err.Raise IMPORT_ERROR
                End If
            
            Case Is = 25
                If TestValue <> "!" Then Err.Raise IMPORT_ERROR
            
        End Select
        
        Next
        ParseAsset = 0
Exit Function
        
ValidationError:
    
Exit Function

ErrorExit:

'    ***CleanUpCode***
    ParseAsset = 999

Exit Function

ErrorHandler:
        
    If Err.Number >= 1000 And Err.Number <= 1500 Then
        If Err.Number = IMPORT_ERROR Then
            ParseAsset = i
            Stop
            Resume ValidationError
        End If
    End If

    
    If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' GetDBVer
' Returns the version of the DB
' ---------------------------------------------------------------
Public Function GetDBVer() As String
    Dim DBVer As Recordset
    
    Const StrPROCEDURE As String = "GetDBVer()"

    On Error GoTo ErrorHandler

    Set DBVer = SQLQuery("TblDBVersion")

    GetDBVer = DBVer.Fields(0)

    Set DBVer = Nothing
    
Exit Function

ErrorExit:

    GetDBVer = ""
    
    Set DBVer = Nothing

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' BuildAsset
' Takes Asset array and build Asset Class
' ---------------------------------------------------------------
Private Function BuildAsset(AssetData() As String) As ClsAsset
    Dim Asset As ClsAsset
    
    Const StrPROCEDURE As String = "BuildAsset()"

    On Error GoTo ErrorHandler

    Set Asset = New ClsAsset

    With Asset
        .AssetNo = AssetData(0)
        .AllocationType = AssetData(1)
        .Brand = AssetData(2)
        .Description = AssetData(3)
        If AssetData(4) <> "" Then .QtyInStock = AssetData(4)
        .Category1 = AssetData(5)
        .Category2 = AssetData(6)
        .Category3 = AssetData(7)
        .Size1 = AssetData(8)
        .Size2 = AssetData(9)
        .PurchaseUnit = AssetData(10)
        .MinAmount = AssetData(11)
        .MaxAmount = AssetData(12)
        .OrderLevel = AssetData(13)
        If AssetData(14) <> "" Then .LeadTime = CInt(AssetData(14))
        .Keywords = AssetData(15)
        .AllowedOrderReasons = AssetData(16)
        .AdditInfo = AssetData(17)
        .NoOrderMessage = AssetData(18)
        .Location = AssetData(19)
        If AssetData(20) <> "" Then .Status = AssetData(20)
        If AssetData(21) <> "" Then .cost = CInt(AssetData(21))
'        .Supplier1 = AssetData(22)
'        .Supplier2 = AssetData(23)
    
    End With

    Set BuildAsset = Asset
    Set Asset = Nothing
Exit Function

ErrorExit:

'    ***CleanUpCode***
    BuildAsset = False
    Set Asset = Nothing

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function
