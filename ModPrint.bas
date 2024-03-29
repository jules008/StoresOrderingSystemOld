Attribute VB_Name = "ModPrint"
'===============================================================
' Module ModPrint
' v0,0 - Initial Version
' v0,1 - added PrintOrderList procedure
' v0,2 - Change from Location object to string
' v0,3 - Added Location to Print Order Form
' v0,4 - Print two copies of Order Form
' v0,5 - Call clearform function correctly
' v0,6 - Add location to receipt
' v0,7 - Print via PDF of direct
' v0,8 - Sort Order list by location
' v0,9 - Printer issue fix
' v0,10 - Added Order Date to Order Form.  Removed PDF Print
' v0,11 - Added Return Required flag to Order List Printout
'---------------------------------------------------------------
' Date - 07 Nov 17
'===============================================================

Option Explicit

Private Const StrMODULE As String = "ModPrint"

' ===============================================================
' CreateTmpFile
' Creates and returns a new temp file
' ---------------------------------------------------------------
Public Function CreateTmpFile() As String
    Dim iFile As Integer
    Dim i As Integer
    Dim FileTxt As String
    Dim TmpFilePath As String
    
    Const StrPROCEDURE As String = "CreateTmpFile()"

    On Error GoTo ErrorHandler

    TmpFilePath = TMP_FILE_PATH

    If Right$(TmpFilePath, 1) <> "\" Then TmpFilePath = TmpFilePath & "\"

    iFile = FreeFile()
    
    Do
        i = i + 1
    Loop While Dir(TmpFilePath & "TmpFile" & i & ".txt") <> vbNullString
    
    Open TmpFilePath & "TmpFile" & i & ".txt" For Append As #iFile
    Close #iFile
    
    CreateTmpFile = TmpFilePath & "TmpFile" & i & ".txt"

Exit Function

ErrorExit:

'    ***CleanUpCode***
    CreateTmpFile = ""

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' PrintOrderReceipt
' Prints a text file
' ---------------------------------------------------------------
Public Function PrintOrderReceipt(Order As ClsOrder) As Boolean
    Dim PrintFilePath As String
    Dim iFile As Integer
    Dim i As Integer
    Dim StationID As String
    Dim StationName As String
    Dim VehReg As String
    Dim Lineitem As ClsLineItem
    Dim DeliveryTo As String
    
    Const StrPROCEDURE As String = "PrintOrderReceipt()"

    On Error GoTo ErrorHandler

    With Order
        Select Case .LineItems(i + 1).Asset.AllocationType
            Case Person
                DeliveryTo = .LineItems(i + 1).ForPerson.Station.Name & " (" & .LineItems(i + 1).ForPerson.UserName & ")"
                
            Case Vehicle
                VehReg = .LineItems(i + 1).ForVehicle.VehReg
                StationID = .LineItems(i + 1).ForVehicle.StationID
                
                If StationID <> "" Then
                    StationName = Stations(StationID).Name
                Else
                    StationName = "No Station"
                End If
                
                DeliveryTo = StationName & " (" & VehReg & ")"
    
            Case Station
                DeliveryTo = .LineItems(i + 1).ForStation.Name
            
        End Select
    
    PrintFilePath = CreateTmpFile
    
    iFile = FreeFile()
    
        Open PrintFilePath For Append As #iFile
            Print #iFile, "==================================================="
            Print #iFile,
            Print #iFile, "Order No: " & .OrderNo
            Print #iFile, "Order Date: " & .OrderDate
            Print #iFile, "Requested By: " & .Requestor.CrewNo & " " & .Requestor.UserName
            Print #iFile, "Station: " & .Requestor.Station.Name
            Print #iFile,
                        
            For Each Lineitem In .LineItems
                With Lineitem
                    Print #iFile,
                    Print #iFile, "---------------------------------------------------"
                    Print #iFile, "Desc: " & .Asset.Description
                    Print #iFile, "Qty: " & .Quantity
                    Print #iFile, "Size1: " & .Asset.Size1
                    Print #iFile, "Size2: " & .Asset.Size2
                    Print #iFile, "For: " & DeliveryTo
                End With
            Next
            Print #iFile, "==================================================="
            Print #iFile,
            Print #iFile,
            Print #iFile,
            Print #iFile,
        Close #iFile
        
        If ENABLE_PRINT Then Shell ("notepad.exe /p " & PrintFilePath)
        
        Kill PrintFilePath
        
        Set Lineitem = Nothing
    End With
    
    PrintOrderReceipt = True

Exit Function

ErrorExit:

'    ***CleanUpCode***
    Set Lineitem = Nothing
    PrintOrderReceipt = False

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' PrintOrderList
' Populates form with order items
' ---------------------------------------------------------------
Public Function PrintOrderList(Order As ClsOrder, PrintOrder As Boolean) As Boolean
    Dim RngOrderNo As Range
    Dim FilePath As String
    Dim RngReqBy As Range
    Dim RngStation As Range
    Dim RngItemsRefPnt As Range
    Dim RngOrders As Range
    Dim RngDate As Range
    Dim RngReturn As Range
    Dim VehReg As String
    Dim StationName As String
    Dim StationID As String
    Dim DeliveryTo As String
    Dim Lineitem As ClsLineItem
    Dim i As Integer
    
    Const StrPROCEDURE As String = "PrintOrderList()"

    ModLibrary.PerfSettingsOn

    On Error GoTo ErrorHandler

    If Not ShtOrderList.ClearForm Then Err.Raise HANDLED_ERROR
    
    Set RngOrderNo = ShtOrderList.Range("C3")
    Set RngReqBy = ShtOrderList.Range("H3")
    Set RngStation = ShtOrderList.Range("J3")
    Set RngReturn = ShtOrderList.Range("K3")
    Set RngItemsRefPnt = ShtOrderList.Range("B6")
    Set RngOrders = ShtOrderList.Range("B6:J39")
    Set RngDate = ShtOrderList.Range("E3")
    
    With Order
        RngOrderNo = .OrderNo
        RngDate = .OrderDate
        RngReqBy = .Requestor.UserName
        RngStation = .Requestor.Station.Name
        
        For i = 0 To .LineItems.Count - 1

            Select Case .LineItems(i + 1).Asset.AllocationType
                Case Person
                    DeliveryTo = .LineItems(i + 1).ForPerson.Station.Name & " (" & .LineItems(i + 1).ForPerson.UserName & ")"
                    
                Case Vehicle
                    VehReg = .LineItems(i + 1).ForVehicle.VehReg
                    StationID = .LineItems(i + 1).ForVehicle.StationID
                    
                    If StationID <> "" Then
                        StationName = Stations(StationID).Name
                    Else
                        StationName = "No Station"
                    End If
                    
                    DeliveryTo = StationName & " (" & VehReg & ")"
        
                Case Station
                    DeliveryTo = .LineItems(i + 1).ForStation.Name
                
            End Select
                
            
            RngItemsRefPnt.Offset(i, 0) = .LineItems(i + 1).Asset.Description
            RngItemsRefPnt.Offset(i, 4) = .LineItems(i + 1).Quantity
            RngItemsRefPnt.Offset(i, 5) = .LineItems(i + 1).Asset.Size1
            RngItemsRefPnt.Offset(i, 6) = .LineItems(i + 1).Asset.Size2
            RngItemsRefPnt.Offset(i, 7) = .LineItems(i + 1).Asset.Location
            RngItemsRefPnt.Offset(i, 8) = DeliveryTo
            
            If .LineItems(i + 1).ReturnReqd Then RngItemsRefPnt.Offset(i, 9) = "Yes"
        Next
    End With
    
    'sort order list by location
    RngOrders.Sort key1:=RngOrders.Cells(1, 8)
    
    If ENABLE_PRINT Then
        
        ShtOrderList.Visible = xlSheetVisible
        
        ShtOrderList.PrintOut copies:=2
        
        ShtOrderList.Visible = xlSheetHidden
    End If
    
GracefulExit:
    
    ModLibrary.PerfSettingsOff
    PrintOrderList = True
    
    Set RngOrderNo = Nothing
    Set RngReqBy = Nothing
    Set RngStation = Nothing
    Set RngOrders = Nothing
    Set RngItemsRefPnt = Nothing
    Set Lineitem = Nothing
    Set RngDate = Nothing
    Set RngReturn = Nothing
    
Exit Function

ErrorExit:
    Set RngOrderNo = Nothing
    Set RngReqBy = Nothing
    Set RngStation = Nothing
    Set RngOrders = Nothing
    Set RngItemsRefPnt = Nothing
    Set Lineitem = Nothing
    Set RngDate = Nothing
    Set RngReturn = Nothing
    
    ModLibrary.PerfSettingsOff

'    ***CleanUpCode***
    PrintOrderList = False

Exit Function

ErrorHandler:
    
    If Err.Number >= 1000 And Err.Number <= 1500 Then
        CustomErrorHandler Err.Number
        Resume GracefulExit:
    End If

    If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

