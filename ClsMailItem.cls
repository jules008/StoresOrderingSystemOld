VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ClsMailItem"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'===============================================================
' v0,0 - Initial version
'---------------------------------------------------------------
' Date - 12 Oct 16
'===============================================================
' Methods
'---------------------------------------------------------------
' LoadDB - Load Item from DB
' NewDB - creates a new Item in the DB
' UpdateDB - Update Item to database
' DeleteDB - Delete Item from database
'===============================================================
Option Explicit
Private pEmailNo As Integer
Private pCrewNo As String
Private pMailTo As String
Private pMailFrom As String
Private pCC As String
Private pSubject As String
Private pBody As String
Private ptimeSent As Date

'----------------------------------------------------------
Public Property Get EmailNo() As Integer
    EmailNo = pEmailNo
End Property

Public Property Let EmailNo(ByVal VnewValue As Integer)
    pEmailNo = VnewValue
End Property

'----------------------------------------------------------
Public Property Get CrewNo() As String
    CrewNo = pCrewNo
End Property

Public Property Let CrewNo(ByVal VnewValue As String)
    pCrewNo = VnewValue
End Property

'----------------------------------------------------------
Public Property Get MailTo() As String
    MailTo = pMailTo
End Property

Public Property Let MailTo(ByVal VnewValue As String)
    pMailTo = VnewValue
End Property

'----------------------------------------------------------
Public Property Get MailFrom() As String
    MailFrom = pMailFrom
End Property

Public Property Let MailFrom(ByVal VnewValue As String)
    pMailFrom = VnewValue
End Property

'----------------------------------------------------------
Public Property Get CC() As String
    CC = pCC
End Property

Public Property Let CC(ByVal VnewValue As String)
    pCC = VnewValue
End Property

'----------------------------------------------------------
Public Property Get Subject() As String
    Subject = pSubject
End Property

Public Property Let Subject(ByVal VnewValue As String)
    pSubject = VnewValue
End Property

'----------------------------------------------------------
Public Property Get Body() As String
    Body = pBody
End Property

Public Property Let Body(ByVal VnewValue As String)
    pBody = VnewValue
End Property

'----------------------------------------------------------
Public Property Get timeSent() As Date
    timeSent = ptimeSent
End Property

Public Property Let timeSent(ByVal VnewValue As Date)
    ptimeSent = VnewValue
End Property

'===============================================================
'Method LoadDB
'load Item from database
'---------------------------------------------------------------
Public Sub LoadDB()
    Dim RstMailItems As Recordset
    
    Set RstMailItems = ModDatabase.SQLQuery("SELECT * FROM mailitems WHERE EmailNo = " & pEmailNo & _
                                        " AND deleted IS NULL")
                                        
    With RstMailItems
        If .RecordCount > 0 Then
            If Not IsNull(!EmailNo) Then pEmailNo = !EmailNo
            If Not IsNull(!CrewNo) Then pCrewNo = !CrewNo
            If Not IsNull(!MailTo) Then pMailTo = !MailTo
            If Not IsNull(!MailFrom) Then pMailFrom = !MailFrom
            If Not IsNull(!Subject) Then pSubject = !Subject
            If Not IsNull(!Body) Then pBody = !Body
            If Not IsNull(!timeSent) Then ptimeSent = !timeSent
        End If
    End With
    Set RstMailItems = Nothing
End Sub

'===============================================================
'Method NewDB
'Creates a new item in the DB
'---------------------------------------------------------------
Public Function NewDB() As Integer
    Dim RstMailItems As Recordset
    
    Set RstMailItems = ModDatabase.SQLQuery("mailitems")
        
    With RstMailItems
        .addnew
        NewDB = !EmailNo
        !CrewNo = pCrewNo
        .Update
    End With
    
    Set RstMailItems = Nothing
End Function

'===============================================================
'Method UpdateDB
'Update session to database
'---------------------------------------------------------------
Public Function UpdateDB() As Boolean
    Dim RstMailItems As Recordset

    Set RstMailItems = ModDatabase.SQLQuery("SELECT * FROM mailitems WHERE EmailNo = " & pEmailNo & _
                                        " AND deleted IS NULL")
    
    
    With RstMailItems
        If .RecordCount = 0 Then
            UpdateDB = False
        Else
            .Edit
            !MailTo = pMailTo
            !MailFrom = pMailFrom
            !Subject = pSubject
            !Body = pBody
            !timeSent = ptimeSent
            .Update
            UpdateDB = True
        End If
    End With
    
    Set RstMailItems = Nothing

End Function

'===============================================================
'Method DeleteDB
' Delete session from database
'---------------------------------------------------------------
Public Sub DeleteDB()
    Dim RstMailItems As Recordset
    
    Set RstMailItems = ModDatabase.SQLQuery("SELECT * FROM mailitems WHERE EmailNo = " & pEmailNo & _
                                        " AND deleted IS NULL")
        
    With RstMailItems
        If .RecordCount <> 0 Then
            .Edit
            !Deleted = Now
            .Update
        End If
    End With
    Set RstMailItems = Nothing
End Sub
