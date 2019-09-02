object Form3: TForm3
  Left = 0
  Top = 0
  Caption = 'Form3'
  ClientHeight = 307
  ClientWidth = 469
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 12
    Top = 48
    Width = 53
    Height = 13
    Caption = 'SQL server'
  end
  object Label2: TLabel
    Left = 8
    Top = 80
    Width = 46
    Height = 13
    Caption = 'DataBase'
  end
  object Label3: TLabel
    Left = 20
    Top = 138
    Width = 67
    Height = 13
    Caption = #1055#1077#1088#1080#1086#1076' ('#1084#1080#1085')'
  end
  object Label4: TLabel
    Left = 40
    Top = 162
    Width = 37
    Height = 13
    Caption = #1053#1072#1095#1072#1083#1086
  end
  object Label5: TLabel
    Left = 31
    Top = 197
    Width = 56
    Height = 13
    Caption = #1054#1082#1086#1085#1095#1072#1085#1080#1077
  end
  object Button1: TButton
    Left = 71
    Top = 14
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 0
    OnClick = Button1Click
  end
  object M1: TMemo
    Left = 271
    Top = 8
    Width = 185
    Height = 291
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object E1: TEdit
    Left = 71
    Top = 45
    Width = 178
    Height = 21
    TabOrder = 2
    Text = 'S-Europay'
  end
  object E2: TEdit
    Left = 71
    Top = 72
    Width = 178
    Height = 21
    TabOrder = 3
    Text = 'Translog'
  end
  object ChB1: TCheckBox
    Left = 76
    Top = 112
    Width = 145
    Height = 17
    Caption = #1055#1077#1088#1080#1086#1076#1080#1095#1077#1089#1082#1080#1081' '#1079#1072#1087#1091#1089#1082
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object Edit1: TEdit
    Left = 93
    Top = 135
    Width = 28
    Height = 21
    TabOrder = 5
    Text = '30'
  end
  object DTPStart: TDateTimePicker
    Left = 93
    Top = 162
    Width = 72
    Height = 21
    Date = 39239.375000000000000000
    Time = 39239.375000000000000000
    DateMode = dmUpDown
    Kind = dtkTime
    TabOrder = 6
  end
  object DTPEnd: TDateTimePicker
    Left = 93
    Top = 189
    Width = 72
    Height = 21
    Date = 39239.750000000000000000
    Time = 39239.750000000000000000
    Kind = dtkTime
    TabOrder = 7
  end
end
