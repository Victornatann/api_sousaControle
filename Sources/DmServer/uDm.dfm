object DM: TDM
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 206
  Width = 128
  object FDConnection: TFDConnection
    Params.Strings = (
      'DriverID=FB'
      'CharacterSet=UTF8'
      'Protocol=Local'
      'User_Name=sysdba'
      'Password=masterkey')
    LoginPrompt = False
    Left = 48
    Top = 24
  end
  object FDGUIxWaitCursor: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 48
    Top = 80
  end
  object FDPhysFBDriverLink: TFDPhysFBDriverLink
    Left = 48
    Top = 136
  end
end
