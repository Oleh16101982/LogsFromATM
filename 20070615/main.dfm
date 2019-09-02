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
    Left = 267
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
end
