VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ClsOrder"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'===============================================================
' Class ClsOrder
' v0,0 - Initial Version
' v0,1 - Added Deleted status
' v0,2 - Fix Assigned To issue
' v0,3 - Added new property PhoneOrder
' v0,4 - Changed DBGet to stop updating pOrderNo
' v0,5 - DBGet now returns deleted orders as well
' v0,6 - Added Order Note and Printed Date
' v0,7 - Cascade delete to lineitems and remove delete from DBsave filter
'---------------------------------------------------------------
' Date - 02 Oct 17
'===============================================================
' Methods
'---------------------------------------------------------------
' DBGet - Gets class from Database
' DBSave - Saves class to Database
' DBDelete(Optional FullDelete As Boolean) - Marks record as deleted or fully deletes
' Submit - Submits order for processing
' ChangeStatus - Manually changes status of order
' UpdateStatus - Automatically updates the status of the order
'===============================================================

Option Explicit
Private pDeleted As Date
Private pOrderNo As Integer
Private pRequestor As ClsPerson
Private pAssignedTo As ClsPerson
Private pLineItems As ClsLineItems
Private pAuthorisedBy As ClsPerson
Private pOrderDate As Date
Private pStatus As EnumOrderStatus
Private pPhoneOrder As Boolean
Private pPrintedDate As Date
Private pOrderNote As String

'---------------------------------------------------------------
Public Property Get Deleted() As Date
    Deleted = pDeleted
End Property

Public Property Let Deleted(ByVal VnewValue As Date)
    pDeleted = VnewValue
    If pDeleted = 0 Then pStatus = OrderOpen Else pStatus = OrderDeleted
End Property

'---------------------------------------------------------------
Public Property Get OrderNo() As Integer
    OrderNo = pOrderNo
End Property

Public Property Let OrderNo(ByVal VnewValue As Integer)
    pOrderNo = VnewValue
End Property

'---------------------------------------------------------------
Public Property Get Requestor() As ClsPerson
    Set Requestor = pRequestor
End Property

Public Property Let Requestor(ByVal VnewValue As ClsPerson)
    Set pRequestor = VnewValue
End Property

'---------------------------------------------------------------
Public Property Get AssignedTo() As ClsPerson
    Set AssignedTo = pAssignedTo
End Property

Public Property Let AssignedTo(ByVal VnewValue As ClsPerson)
    Set pAssignedTo = VnewValue
End Property

'---------------------------------------------------------------
Public Property Get LineItems() As ClsLineItems
    Set LineItems = pLineItems
End Property

Public Property Let LineItems(ByVal VnewValue As ClsLineItems)
    Set pLineItems = VnewValue
End Property

'---------------------------------------------------------------
Public Property Get AuthorisedBy() As ClsPerson
    Set AuthorisedBy = pAuthorisedBy
End Property

Public Property Let AuthorisedBy(ByVal VnewValue As ClsPerson)
    Set pAuthorisedBy = VnewValue
End Property

'---------------------------------------------------------------
Public Property Get OrderDate() As Date
    OrderDate = pOrderDate
End Property

Public Property Let OrderDate(ByVal VnewValue As Date)
    pOrderDate = VnewValue
End Property

'---------------------------------------------------------------
Public Property Get Status() As EnumOrderStatus
    Status = pStatus
End Property

Public Property Let Status(ByVal VnewValue As EnumOrderStatus)
    pStatus = VnewValue
End Property

'---------------------------------------------------------------
Public Property Get PhoneOrder() As Boolean
    PhoneOrder = pPhoneOrder
End Property

Public Property Let PhoneOrder(ByVal VnewValue As Boolean)
    pPhoneOrder = VnewValue
End Property

'---------------------------------------------------------------
Public Property Get PrintedDate() As Date
    PrintedDate = pPrintedDate
End Property

Public Property Let PrintedDate(ByVal vNewValue As Date)
    pPrintedDate = vNewValue
End Property

'---------------------------------------------------------------
Public Property Get OrderNote() As String
    OrderNote = pOrderNote
End Property

Public Property Let OrderNote(ByVal vNewValue As String)
    pOrderNote = vNewValue
End Property

'---------------------------------------------------------------
' ===============================================================
' Method DBGet
' Gets class from Database
'---------------------------------------------------------------
Public Sub DBGet(OrderNo As Integer)
    Dim RstOrder As Recordset
        
    Set RstOrder = ModDatabase.SQLQuery("SELECT * FROM TblOrder WHERE OrderNo = " & OrderNo)
    With RstOrder
        If .RecordCount > 0 Then
            If Not IsNull(!Deleted) Then pDeleted = !Deleted
            If Not IsNull(!OrderNo) Then pOrderNo = !OrderNo
            If Not IsNull(!OrderDate) Then pOrderDate = !OrderDate
            If Not IsNull(!Status) Then pStatus = !Status
            If Not IsNull(!PrintedDate) Then pPrintedDate = !PrintedDate
            If Not IsNull(!OrderNote) Then pOrderNote = !OrderNote
            If Not IsNull(!RequestorID) Then pRequestor.DBGet !RequestorID
            If Not IsNull(!AssignedToID) Then pAssignedTo.DBGet !AssignedToID
            If Not IsNull(!AuthorisedByID) Then pAuthorisedBy.DBGet !AuthorisedByID

            pLineItems.GetCollection
        End If
    End With
Set RstOrder = Nothing
End Sub

' ===============================================================
' Method DBSave
' Saves class to Database
'---------------------------------------------------------------
Public Sub DBSave()
    Dim RstOrder As Recordset
    Dim RstMaxNo As Recordset
    Dim LastNo As Integer
    Dim Lineitem As ClsLineItem

    Set RstOrder = ModDatabase.SQLQuery("SELECT * FROM TblOrder WHERE OrderNo = " & pOrderNo)
    Set RstMaxNo = ModDatabase.SQLQuery("SELECT MAX(OrderNo) FROM TblOrder ")

    If RstMaxNo.Fields(0).Value <> 0 Then
        LastNo = RstMaxNo.Fields(0).Value
    Else
        LastNo = 0
    End If

    With RstOrder
        If .RecordCount = 0 Then
            .addnew
            pOrderNo = LastNo + 1
        Else
            .Edit
        End If
        !OrderNo = pOrderNo
        If Requestor.CrewNo <> "" Then !RequestorID = pRequestor.CrewNo
        If pAssignedTo.CrewNo <> "" Then !AssignedToID = pAssignedTo.CrewNo
        If pAuthorisedBy.UserName <> "" Then !AuthorisedByID = pAuthorisedBy.UserName
        If pOrderDate <> 0 Then !OrderDate = pOrderDate
        If pDeleted <> 0 Then !Deleted = pDeleted
        If pPrintedDate <> 0 Then !PrintedDate = pPrintedDate
        If pOrderNote <> "" Then !OrderNote = pOrderNote
        !Status = pStatus
        .Update
        
        For Each Lineitem In pLineItems
            Lineitem.DBSave
        Next

    End With
    Set Lineitem = Nothing
    Set RstOrder = Nothing
    Set RstMaxNo = Nothing
End Sub

' ===============================================================
' Method DBDelete(Optional FullDelete As Boolean)
' Marks record as deleted or fully deletes
'---------------------------------------------------------------
Public Sub DBDelete(Optional FullDelete As Boolean)
    Dim RstOrder As Recordset
    Dim LineItem As ClsLineItem
    
    Dim i As Integer

    Set RstOrder = ModDatabase.SQLQuery("SELECT * FROM TblOrder WHERE OrderNo = " & pOrderNo & " AND Deleted IS NULL")
    With RstOrder
        For i = .RecordCount To 1 Step -1
            If FullDelete Then
                .Delete
                .MoveNext
                For Each LineItem In pLineItems
                    LineItem.DBDelete True
                Next
            Else
                .Edit
                !Deleted = Now
                .Update
                For Each LineItem In pLineItems
                    LineItem.DBDelete
                Next

            End If
        Next
    End With

    Set RstOrder = Nothing
End Sub

' ===============================================================
' ReturnOrderStatus
' Returns string value from enumOrderStatus
' ---------------------------------------------------------------
Public Function ReturnOrderStatus() As String
    Const StrPROCEDURE As String = "ReturnOrderStatus()"
    Dim RstOrderStatus As Recordset
    
    Set RstOrderStatus = ModDatabase.SQLQuery("SELECT OrderStatus FROM TblOrderStatus WHERE OrderStatusNo = " & pStatus)
    
    With RstOrderStatus
        If .RecordCount > 0 Then ReturnOrderStatus = !OrderStatus
    
    End With
    
    Set RstOrderStatus = Nothing


End Function

' ===============================================================
' ReturnOrderStatusList
' Returns complete list of order statuses
' ---------------------------------------------------------------
Public Function ReturnOrderStatusList() As Recordset
    Const StrPROCEDURE As String = "ReturnOrderStatusList()"
    Dim RstOrderStatus As Recordset
    
    Set RstOrderStatus = ModDatabase.SQLQuery("TblOrderStatus")
    
    With RstOrderStatus
        If .RecordCount > 0 Then Set ReturnOrderStatusList = RstOrderStatus
    End With
    
    Set RstOrderStatus = Nothing

End Function

' ===============================================================
Private Sub Class_Initialize()
    Set pRequestor = New ClsPerson
    Set pAssignedTo = New ClsPerson
    Set pLineItems = New ClsLineItems
    Set pAuthorisedBy = New ClsPerson

    pLineItems.SetParent ObjPtr(Me)
End Sub

'---------------------------------------------------------------
Private Sub Class_Terminate()
    pLineItems.SetParent 0
    
    Set pRequestor = Nothing
    Set pAssignedTo = Nothing
    Set pLineItems = Nothing
    Set pAuthorisedBy = Nothing

End Sub

'---------------------------------------------------------------
