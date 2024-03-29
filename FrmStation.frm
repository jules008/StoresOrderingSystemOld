VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} FrmStation 
   ClientHeight    =   6240
   ClientLeft      =   45
   ClientTop       =   375
   ClientWidth     =   8490
   OleObjectBlob   =   "FrmStation.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "FrmStation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'===============================================================
' v0,0 - Initial version
' v0,1 - Bug fix for Phone Order
' v0,2 - Bug fix when using using Prev Button
' v0,3 - Clean up if user cancels order
' v0,4 - Bug fix - phone order not filling in ForStation
'---------------------------------------------------------------
' Date - 15 Jun 17
'===============================================================
Option Explicit

Private Const StrMODULE As String = "FrmStation"

Private Lineitem As ClsLineItem

' ===============================================================
' ShowForm
' Initial entry point to form
' ---------------------------------------------------------------
Public Function ShowForm(Optional LocLineItem As ClsLineItem) As Boolean
    
    Const StrPROCEDURE As String = "ShowForm()"
    
    On Error GoTo ErrorHandler
    
    If LocLineItem Is Nothing Then
        Err.Raise NO_LINE_ITEM, Description:="No Line Item Passed to ShowForm Function"
    Else
        Set Lineitem = LocLineItem
        If Not PopulateForm Then Err.Raise HANDLED_ERROR
    End If
    
    Show
    ShowForm = True

Exit Function

ErrorExit:

    FormTerminate
    Terminate
    ShowForm = False

Exit Function

ErrorHandler:
    
    If Err.Number >= 1000 And Err.Number <= 1500 Then
        CustomErrorHandler Err.Number
        Resume Next
    End If

    If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' PopulateForm
' Populates form controls
' ---------------------------------------------------------------
Private Function PopulateForm() As Boolean
    Dim Station As ClsStation
    Dim i As Integer
    
    Const StrPROCEDURE As String = "PopulateForm()"

    On Error GoTo ErrorHandler
    
    Set Station = Lineitem.Parent.Requestor.Station
    
    If Station.StationID <> 0 Then
    
        LblText2.Visible = False
        LstStations.Visible = False
    
        With LblAllocation
            .Visible = True
            .Caption = "What Station is this item for?"
        End With
        
        With OptMe
            .Visible = True
            .Caption = Format(Station.StationNo, "00") & " " & Station.Name
        End With
        
        With OptElse
            .Visible = True
        End With
    Else
        LblAllocation.Visible = False
        OptMe.Visible = False
        OptElse.Visible = False
        
        If Not ShowOtherStations Then Err.Raise HANDLED_ERROR
    End If
    
    PopulateForm = True

Exit Function

ErrorExit:
    PopulateForm = False
    FormTerminate
    Terminate

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' CancelOrder
' Cleans up after order is cancelled
' ---------------------------------------------------------------
Private Function CancelOrder() As Boolean
    Const StrPROCEDURE As String = "CancelOrder()"

    On Error GoTo ErrorHandler

    Lineitem.Parent.LineItems.RemoveItem (CStr(Lineitem.LineItemNo))

    CancelOrder = True

Exit Function

ErrorExit:

'    ***CleanUpCode***
    CancelOrder = False

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' FormTerminate
' Terminates the form gracefully
' ---------------------------------------------------------------
Private Function FormTerminate() As Boolean

    On Error Resume Next

    Set Lineitem = Nothing
    Unload Me

End Function

' ===============================================================
' BtnClose_Click
' Event for page close button
' ---------------------------------------------------------------
Private Sub BtnClose_Click()

    On Error Resume Next
    
    If Not CancelOrder Then Err.Raise HANDLED_ERROR
    
    FormTerminate
    
End Sub

' ===============================================================
' UserForm_QueryClose
' Tidies up if user cancels order
' ---------------------------------------------------------------
Private Sub UserForm_QueryClose(Cancel As Integer, CloseMode As Integer)

    If CloseMode = 0 Then
        If Not CancelOrder Then Err.Raise HANDLED_ERROR
    End If
End Sub

' ===============================================================
' BtnNext_Click
' Moves onto next form
' ---------------------------------------------------------------
Private Sub BtnNext_Click()
    Dim StrUserName As String
    
    Const StrPROCEDURE As String = "BtnNext_Click()"

    On Error GoTo ErrorHandler

        Select Case ValidateForm
    
            Case Is = FunctionalError
                Err.Raise HANDLED_ERROR
            
            Case Is = FormOK
        
                If Lineitem Is Nothing Then Err.Raise SYSTEM_FAILURE, Description:="No LineItem Available"
                
                If OptMe = True Then
                    Lineitem.ForStation = Lineitem.Parent.Requestor.Station
                Else
                    Lineitem.ForStation = Stations(CStr(LstStations.ListIndex))
                End If
                
                If Lineitem.ForStation Is Nothing Then Err.Raise HANDLED_ERROR
                      
                Hide
                If Not FrmLossReport.ShowForm(Lineitem) Then Err.Raise HANDLED_ERROR
                Unload Me
                 
        End Select
        
GracefulExit:

Exit Sub

ErrorExit:

    FormTerminate
    Terminate

Exit Sub

ErrorHandler:
    
    If Err.Number >= 1000 And Err.Number <= 1500 Then
        CustomErrorHandler Err.Number
        Resume GracefulExit
    End If

    If CentralErrorHandler(StrMODULE, StrPROCEDURE, , True) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Sub

' ===============================================================
' BtnPrev_Click
' Back to previous screen event
' ---------------------------------------------------------------
Private Sub BtnPrev_Click()
    Const StrPROCEDURE As String = "BtnPrev_Click()"

    On Error GoTo ErrorHandler

    Hide
    If Not FrmCatSearch.ShowForm(Lineitem) Then Err.Raise HANDLED_ERROR
Exit Sub

ErrorExit:
    FormTerminate
    Terminate
Exit Sub

ErrorHandler:

    If CentralErrorHandler(StrMODULE, StrPROCEDURE, , True) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Sub

' ===============================================================
' LstStations_Click
' Event processing for Station list
' ---------------------------------------------------------------
Private Sub LstStations_Click()
    
    Const StrPROCEDURE As String = "LstStation_Click()"
    
    On Error GoTo ErrorHandler
    
    With LstStations
        Lineitem.ForStation = Stations(.List(.ListIndex, 0))
    End With

Exit Sub

ErrorExit:
    FormTerminate
    Terminate

Exit Sub

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE, , True) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Sub

' ===============================================================
' OptElse_Click
' Processes who the item is for
' ---------------------------------------------------------------
Private Sub OptElse_Click()
    Const StrPROCEDURE As String = "OptElse_Click()"
    
    Dim i As Integer
    
    On Error GoTo ErrorHandler
    
    If Not ShowOtherStations Then Err.Raise HANDLED_ERROR
    
Exit Sub

ErrorExit:

    FormTerminate
    Terminate

Exit Sub

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE, , True) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Sub


' ===============================================================
' OptMe_Click
' User has selected item is for them
' ---------------------------------------------------------------
Private Sub OptMe_Click()
    Const StrPROCEDURE As String = "OptMe_Click()"

    On Error GoTo ErrorHandler

    With LblText2
        .Visible = False
    End With
    
    With LstStations
        .Visible = False
    End With

    
Exit Sub

ErrorExit:

    FormTerminate
    Terminate

Exit Sub

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE, , True) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Sub

' ===============================================================
' UserForm_Initialize
' Automatic initialise event that triggers custom Initialise
' ---------------------------------------------------------------
Private Sub UserForm_Initialize()

    On Error Resume Next
    
    FormInitialise
    
End Sub

' ===============================================================
' UserForm_Terminate
' Automatic Terminate event that triggers custom Terminate
' ---------------------------------------------------------------
Private Sub UserForm_Terminate()

    On Error Resume Next
    
    FormTerminate
    
End Sub

' ===============================================================
' FormInitialise
' initialises controls on form at start up
' ---------------------------------------------------------------
Private Function FormInitialise() As Boolean
    Const StrPROCEDURE As String = "FormInitialise()"
    
    Dim i As Integer
    Dim Station As ClsStation
    
    On Error GoTo ErrorHandler
    
    OptMe.Value = True

    With LstStations
        .Clear
        .Visible = True
        i = 0
        For Each Station In Stations
            .AddItem
            .List(i, 0) = Station.StationNo
            .List(i, 1) = Station.Name
            i = i + 1
        Next
    End With
    
    Set Station = Nothing
    
    FormInitialise = True

Exit Function

ErrorExit:
    
    Set Station = Nothing

    FormTerminate
    Terminate
    
    FormInitialise = False

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' ValidateForm
' Ensures the form is filled out correctly before moving on
' ---------------------------------------------------------------
Private Function ValidateForm() As EnumFormValidation
    Const StrPROCEDURE As String = "ValidateForm()"

    On Error GoTo ErrorHandler
    
    If OptElse Then
        With LstStations
            If .ListIndex = -1 Then
                .BackColor = COLOUR_6
                ValidateForm = ValidationError
            End If
        End With
                            
        If ValidateForm = ValidationError Then
            Err.Raise FORM_INPUT_EMPTY
        Else
            ValidateForm = FormOK
        End If
    End If
    
    ValidateForm = FormOK

GracefulExit:


Exit Function

ErrorExit:

    ValidateForm = FunctionalError
    FormTerminate
    Terminate

Exit Function

ErrorHandler:
    
    If Err.Number >= 1000 And Err.Number <= 1500 Then
        CustomErrorHandler Err.Number
        Resume GracefulExit
    End If

If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

' ===============================================================
' ShowOtherStations
' Shows a list of all stations
' ---------------------------------------------------------------
Private Function ShowOtherStations() As Boolean
    Const StrPROCEDURE As String = "ShowOtherStations()"

    On Error GoTo ErrorHandler

    With LblText2
        .Visible = True
    End With

    LstStations.Visible = True
    
    ShowOtherStations = True

Exit Function

ErrorExit:
    FormTerminate
    Terminate

    ShowOtherStations = False

Exit Function

ErrorHandler:   If CentralErrorHandler(StrMODULE, StrPROCEDURE) Then
        Stop
        Resume
    Else
        Resume ErrorExit
    End If
End Function

