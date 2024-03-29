VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ClsMailSystem"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'==========================================================
' V0,1 - Initial Version
' v0,2 - Attempt at correcting email error
' Date - 11/10/16
'==========================================================
' Methods
'---------------------------------------------------------------

' GetParentFromPtr - Private routine to copy memory address of parent class
' DisplayEmail - displays email before sending
' SendEmail - Sends email without displaying
'===============================================================
Option Explicit
Private pOutlookApp As Outlook.Application
Private pReturnMail As ClsMailItem
Private WithEvents pMailItem As Outlook.MailItem
Attribute pMailItem.VB_VarHelpID = -1

'----------------------------------------------------------
Public Property Get OutlookApp() As Outlook.Application
    Set OutlookApp = pOutlookApp
End Property

Public Property Let OutlookApp(ByVal VnewValue As Outlook.Application)
    Set pOutlookApp = VnewValue
End Property

'----------------------------------------------------------
Public Property Get MailItem() As Outlook.MailItem
    Set MailItem = pMailItem
End Property

Public Property Let MailItem(ByVal VnewValue As Outlook.MailItem)
    Set pMailItem = VnewValue
End Property

'----------------------------------------------------------
Public Property Get ReturnMail() As ClsMailItem
    Set ReturnMail = pReturnMail
End Property

Public Property Let ReturnMail(ByVal VnewValue As ClsMailItem)
    Set pReturnMail = VnewValue
End Property

'===============================================================
'Method DisplayEmail
'displays email before sending
'---------------------------------------------------------------
Public Sub DisplayEmail()
   On Error Resume Next
    With pMailItem
        .Display
    End With
    On Error GoTo 0
End Sub

'===============================================================
'Method SendEmail
'Sends email without displaying
'---------------------------------------------------------------
Public Sub SendEmail()
   On Error Resume Next
    With pMailItem
        If SEND_EMAILS Then .SendEmail
    End With
    On Error GoTo 0
End Sub

'===============================================================
'Method ReturnMailItem
'Returns final mail item after it has been sent
'---------------------------------------------------------------
Private Function ReturnMailItem()
    Dim i As Integer
    
    With pReturnMail
        .MailTo = pMailItem.To
        .Body = pMailItem.Body
        .Subject = pMailItem.Subject
        .timeSent = pMailItem.ReceivedTime
        .MailFrom = Environ("Username")
    End With
End Function

'===============================================================
'Event pMailItem_Send
'saves email details when it has been sent
'---------------------------------------------------------------
Private Sub pMailItem_Send(Cancel As Boolean)
    Debug.Print "Item was sent by " & Environ("Username") & " at " & Now()
    Debug.Print MailItem.Body
    ReturnMailItem
End Sub

'===============================================================
Private Sub Class_Initialize()
    Set pOutlookApp = CreateObject("Outlook.Application")
    Set pMailItem = pOutlookApp.CreateItem(0)
    Set pReturnMail = New ClsMailItem
End Sub

Private Sub Class_Terminate()
    Set pOutlookApp = Nothing
    Set pMailItem = Nothing
    Set pReturnMail = Nothing
End Sub
'===============================================================




