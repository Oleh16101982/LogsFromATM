object frmParsing: TfrmParsing
  Left = 0
  Top = 0
  Caption = #1056#1072#1079#1073#1086#1088' '#1083#1086#1075' '#1092#1072#1081#1083#1086#1074
  ClientHeight = 523
  ClientWidth = 742
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnHide = FormHide
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 220
    Top = 497
    Width = 110
    Height = 13
    Caption = #1055#1077#1088#1077#1093#1086#1076' '#1082' '#1073#1072#1085#1082#1086#1084#1072#1090#1091
  end
  object PC1: TPageControl
    Left = 4
    Top = 6
    Width = 730
    Height = 485
    ActivePage = TabSheet1
    MultiLine = True
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = #1054#1073#1097#1077#1077
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object SG1: TStringGrid
        Left = 0
        Top = 3
        Width = 467
        Height = 451
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        TabOrder = 0
        OnDrawCell = SG1DrawCell
      end
    end
  end
  object CBATM: TComboBox
    Left = 336
    Top = 494
    Width = 213
    Height = 21
    ItemHeight = 0
    TabOrder = 1
  end
end
