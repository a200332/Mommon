// This is part of the Mommon Library
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)

unit mQuickReadOnlyVirtualDataSet;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  DB, Classes, contnrs, Variants,
  mVirtualDataSet, mVirtualDataSetInterfaces, mSortConditions, mFilter, mIntList, mMaps, mLog,
  mJoins;

const
  KEY_FIELD_NAME = '_KEY';

type

  { TReadOnlyVirtualDatasetProvider }

  TReadOnlyVirtualDatasetProvider = class (TVirtualDatasetDataProvider)
  strict private
    FIDataProvider : IVDListDataProvider;
    FSortedIndex : TFPList;
    FFilteredIndex : TIntegerList;
    FCurrentSortFields : TStringList;
    FGarbage : TObjectList;
    FFiltered : boolean;

    function OnCompare(Item1: Pointer;Item2: Pointer):Integer;
    procedure InternalGetFieldValue (const aFieldName : string; const AIndex: Integer; out AValue: variant);
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Init (aDataProvider : IVDListDataProvider);

    procedure GetFieldValue (const AField: TField; const AIndex: Integer; out AValue: variant); override;
    procedure DeleteRecord (const AIndex :integer); override;
    procedure EditRecord (const AIndex : integer; AModifiedFields : TList); override;
    procedure InsertRecord (const AIndex : integer; AModifiedFields : TList); override;
    function GetRecordCount : integer; override;

    function Refresh (const aDoSort, aDoFilter : boolean): boolean; override;
    procedure GetUniqueStringValuesForField(const aFieldName: string; aList: TStringList); override;
  end;

implementation

uses
  SysUtils,
  mUtility;

type
  TDatumShell = class
  public
    Datum : IVDDatum;
    Idx : integer;
  end;

var
  logger : TmLog;

{ TReadOnlyVirtualDatasetProvider }

function TReadOnlyVirtualDatasetProvider.OnCompare(Item1: Pointer;Item2: Pointer):Integer;
var
  d1, d2 : TDatumShell;
  i : integer;
  val1, val2 : Variant;
begin

  d1 := TDatumShell(Item1);
  d2 := TDatumShell(Item2);


  Result := -1;
  for i := 0 to SortConditions.Count -1 do
  begin
    if CompareText(SortConditions.Items[i].FieldName, KEY_FIELD_NAME) = 0 then
    begin
      val1 := d1.Idx;
      val2 := d2.Idx;
    end
    else
    begin
      val1 := d1.Datum.GetPropertyByFieldName(SortConditions.Items[i].FieldName);
      val2 := d2.Datum.GetPropertyByFieldName(SortConditions.Items[i].FieldName);
    end;
    Result := CompareVariants(val1, val2);
    if Result <> 0 then
    begin
      if SortConditions.Items[i].SortType = stDescending then
        Result := -1 * Result;
      break;
    end;
  end;
end;

procedure TReadOnlyVirtualDatasetProvider.InternalGetFieldValue(const aFieldName: string; const AIndex: Integer; out AValue: variant);
var
  tmpI : IVDDatum;
  idx: integer;
  actualIndex : integer;
  tmpPrefix, tmpFieldName : string;
  tmpBuiltinJoin : TmBuiltInJoin;
  tmpJoinKey : TObject;
begin
  if (aIndex >= 0) then
  begin
    if FFiltered then
      actualIndex:= FFilteredIndex.Nums[aIndex]
    else
      actualIndex:= aIndex;
    if FSortedIndex.Count > 0 then
    begin
      tmpI := TDatumShell(FSortedIndex.Items[actualIndex]).Datum;
      idx := TDatumShell(FSortedIndex.Items[actualIndex]).Idx;
    end
    else
    begin
      tmpI := FIDataProvider.GetDatum(actualIndex);
      idx := aIndex;
    end;
    AValue := Null;

   if CompareText(aFieldName, KEY_FIELD_NAME) = 0 then
     aValue := idx
   else
   begin
     if BuiltInJoins.Count > 0 then
     begin
       ExtractPrefixAndFieldName(aFieldName, tmpPrefix, tmpFieldName);
       tmpBuiltinJoin := BuiltInJoins.FindByPrefix(tmpPrefix);
       if Assigned(tmpBuiltinJoin) then
       begin
         tmpJoinKey := tmpBuiltinJoin.BuildExternalEntityKeyFunction(tmpI);
         try
           aValue := tmpBuiltinJoin.Provider.FindDatumByKey(tmpJoinKey as IVDDatumKey).GetPropertyByFieldName(tmpFieldName);
         finally
           tmpJoinKey.Free;
         end;
       end
       else
         aValue := tmpI.GetPropertyByFieldName(aFieldName);
     end
     else
       aValue := tmpI.GetPropertyByFieldName(aFieldName);
   end;
  end
  else
    aValue := null;
end;


constructor TReadOnlyVirtualDatasetProvider.Create;
begin
  inherited Create;
  FSortedIndex := TFPList.Create;
  FFilteredIndex := TIntegerList.Create;
  FCurrentSortFields := TStringList.Create;
  FGarbage := TObjectList.Create(true);
  FFiltered:= false;
end;

destructor TReadOnlyVirtualDatasetProvider.Destroy;
begin
  FIDataProvider := nil;
  FreeAndNil(FSortedIndex);
  FreeAndNil(FCurrentSortFields);
  FreeAndNil(FGarbage);
  FreeAndNil(FFilteredIndex);
  inherited Destroy;
end;


procedure TReadOnlyVirtualDatasetProvider.Init(aDataProvider: IVDListDataProvider);
begin
  FIDataProvider := aDataProvider;
  FSortedIndex.Clear;
  FGarbage.Clear;
end;

procedure TReadOnlyVirtualDatasetProvider.GetFieldValue(const AField: TField; const AIndex: Integer; out AValue: variant);
begin
  InternalGetFieldValue(AField.FieldName, AIndex, AValue);
end;

procedure TReadOnlyVirtualDatasetProvider.DeleteRecord(const AIndex: integer);
begin
  // do nothing
end;

procedure TReadOnlyVirtualDatasetProvider.EditRecord(const AIndex: integer; AModifiedFields: TList);
begin
  // do nothing
end;

procedure TReadOnlyVirtualDatasetProvider.InsertRecord(const AIndex: integer; AModifiedFields: TList);
begin
  // do nothing
end;

function TReadOnlyVirtualDatasetProvider.GetRecordCount: integer;
begin
  if FFiltered then
    Result := FFilteredIndex.Count
  else
    Result := FIDataProvider.Count;
end;

function TReadOnlyVirtualDatasetProvider.Refresh(const aDoSort, aDoFilter: boolean): boolean;
var
  i, k : integer;
  tmp : TDatumShell;
  visibleRow : boolean;
  currentDatum : IVDDatum;
begin
  Result := false;
  if not Assigned(FIDataProvider) then
    exit
  else
  begin
    // http://lazarus-ccr.sourceforge.net/docs/rtl/classes/tfplist.html
    // http://lazarus-ccr.sourceforge.net/docs/lcl/lclproc/mergesort.html
    if (not aDoSort) then
    begin
      FSortedIndex.Clear;
      FGarbage.Clear;
    end
    else
    begin
      FSortedIndex.Clear;
      FGarbage.Clear;
      for i := 0 to FIDataProvider.Count -1 do
      begin
        tmp := TDatumShell.Create;
        FGarbage.Add(tmp);
        tmp.Datum := FIDataProvider.GetDatum(i);
        tmp.Idx:= i;
        FSortedIndex.Add(tmp);
      end;
      FCurrentSortFields.Clear;
      for i := 0 to SortConditions.Count - 1 do
        FCurrentSortFields.Append(SortConditions.Items[i].FieldName);
      mUtility.MergeSort(FSortedIndex, OnCompare);
      FCurrentSortFields.Clear;
    end;
    if (not aDoFilter) then
    begin
      FFilteredIndex.Clear;
      FFiltered := false;
    end
    else
    begin
      FFilteredIndex.Clear;
      FFiltered := true;
      logger.Debug('[TReadOnlyVirtualDatasetProvider.Refresh] - start evaluation to apply filter');

      FilterConditions.StartEvaluation;
      try
        logger.Debug('[TReadOnlyVirtualDatasetProvider.Refresh] - total row:' + IntToStr(FIDataProvider.Count));
        if FSortedIndex.Count > 0 then
        begin
          for i := 0 to FSortedIndex.Count - 1 do
          begin
            visibleRow := true;
            currentDatum := TDatumShell(FSortedIndex.Items[i]).Datum;
            for k := 0 to FilterConditions.Count -1 do
            begin
              visibleRow := visibleRow and FilterConditions.Get(k).Evaluate(CurrentDatum.GetPropertyByFieldName(FilterConditions.Get(k).FieldName));
              if not visibleRow then
                break;
            end;
            if visibleRow then
              FFilteredIndex.Add(i);
          end;
        end
        else
        begin
          for i := 0 to FIDataProvider.Count -1 do
          begin
            visibleRow := true;
            currentDatum := FIDataProvider.GetDatum(i);
            for k := 0 to FilterConditions.Count -1 do
            begin
              visibleRow := visibleRow and FilterConditions.Get(k).Evaluate(CurrentDatum.GetPropertyByFieldName(FilterConditions.Get(k).FieldName));
              if not visibleRow then
                break;
            end;
            if visibleRow then
              FFilteredIndex.Add(i);
          end;
        end;
      finally
        FilterConditions.EndEvaluation;
      end;
      logger.Debug('[TReadOnlyVirtualDatasetProvider.Refresh] - end evaluation. Found:' + IntToStr(FFilteredIndex.Count));
    end;
  end;
  Result := true;
end;

procedure TReadOnlyVirtualDatasetProvider.GetUniqueStringValuesForField(const aFieldName: string; aList: TStringList);
var
  i : integer;
  tmpValue : variant;
  tmpIndex : TmStringDictionary;
  str : String;
begin
  tmpIndex := TmStringDictionary.Create();
  try
    for i := 0 to Self.GetRecordCount - 1 do
    begin
      Self.InternalGetFieldValue(aFieldName, i, tmpValue);

      str := VarToStr(tmpValue);

      if tmpIndex.Find(str) = nil then
      begin
         tmpIndex.Add(str, tmpIndex);
         aList.Add(str);
      end;
    end;
  finally
    tmpIndex.Free;
  end;
end;


initialization
  logger := logManager.AddLog('mQuickReadOnlyVirtualDataSet');

end.
