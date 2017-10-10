// This is part of the KAParser component source
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)

unit KAParser;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, variants, sysutils,
  mArrays;

const
  sInvalidString = 1;
  sSyntaxError = 2;
  sFunctionError = 3;
  sWrongParamCount = 4;

  mP_intfunc_trunc = 'trunc';
  mP_intfunc_sin = 'sin';
  mP_intfunc_cos = 'cos';
  mP_intfunc_tan = 'tan';
  mP_intfunc_frac = 'frac';
  mP_intfunc_int = 'int';

  mP_intconst_now = '_now_';
  mP_intconst_today = '_today_';
  mP_intconst_true = 'true';
  mP_intconst_false = 'false';
  mP_intconst_pi = 'pi';

  mp_specfunc_if = 'if';
  mp_specfunc_empty = 'empty';
  mp_specfunc_len = 'len';
  mp_specfunc_and = 'and';
  mp_specfunc_or = 'or';
  mp_specfunc_safediv = 'safediv';
  mp_specfunc_between = 'between';
  mp_specfunc_concatenate = 'concatenate';
  mp_specfunc_concat = 'concat';
  mp_specfunc_repl = 'repl';
  mp_specfunc_left = 'left';
  mp_specfunc_right = 'right';
  mp_specfunc_substr = 'substr';
  mp_specfunc_tostr = 'tostr';
  mp_specfunc_pos = 'pos';
  mp_specfunc_trim = 'trim';
  mp_specfunc_ltrim = 'ltrim';
  mp_specfunc_rtrim = 'rtrim';
  mp_specfunc_uppercase = 'uppercase';
  mp_specfunc_lowercase = 'lowercase';
  mp_specfunc_compare = 'compare';
  mp_specfunc_comparestr = 'comparestr';
  mp_specfunc_comparetext = 'comparetext';
  mp_specfunc_round = 'round';
  mp_specfunc_ceil = 'ceil';
  mp_specfunc_floor = 'floor';
  mp_specfunc_not = 'not';
  mp_specfunc_sum = 'sum';
  mp_specfunc_max = 'max';
  mp_specfunc_min = 'min';
  mp_specfunc_avg = 'avg';
  mp_specfunc_count = 'count';
  mp_specfunc_now = 'now';
  mp_specfunc_getday = 'getday';
  mp_specfunc_getweek = 'getweek';
  mp_specfunc_getmonth = 'getmonth';
  mp_specfunc_getyear = 'getyear';
  mp_specfunc_startoftheweek = 'startoftheweek';
  mp_specfunc_startofthemonth = 'startofthemonth';
  mp_specfunc_endofthemonth = 'endofthemonth';
  mp_specfunc_todate = 'todate';
  mp_specfunc_todatetime = 'todatetime';
  mp_specfunc_today = 'today';
  mp_specfunc_stringtodatetime = 'stringtodatetime';
  mp_specfunc_todouble = 'todouble';

  mp_rangefunc_childsnotnull = 'childsnotnull';
  mp_rangefunc_parentnotnull = 'parentnotnull';
  mp_rangefunc_parentsnotnull = 'parentsnotnull';
  mp_rangefunc_childs = 'childs';
  mp_rangefunc_parents = 'parents';
  mp_rangefunc_parent = 'parent';

type

  TParserException = class(Exception);

  TCalculationType = (calculateValue, calculateFunction);

  TFormulaToken = (
    tkUndefined, tkEOF, tkERROR,
    tkLBRACE, tkRBRACE, tkNUMBER, tkIDENT, tkSEMICOLON,
    tkPOW,
    tkINV, tkNOT,
    tkMUL, tkDIV, tkMOD, tkPER,
    tkADD, tkSUB,
    tkLT, tkLE, tkEQ, tkNE, tkGE, tkGT,
    tkOR, tkXOR, tkAND, tkString
  );

  TLexResult = record
  private
    FIsInteger : boolean;
    FIsDouble : boolean;
    FIsUndefined : boolean;
  public
    IntValue : integer;
    DoubleValue : double;
    StringValue : string;
    Token : TFormulaToken;

    procedure Clear;

    function IsUndefined : boolean;
    function IsInteger : boolean;
    function IsString : boolean;
    function IsDouble : boolean;

    procedure SetInteger(aValue : integer);
    procedure SetDouble(aValue : double);
    procedure SetString(aValue : string);
  end;

  TLexState = record
  private
    FFormula : string;
    FCharIndex : integer;
    FLenFormula : integer;
  public
    function IsEof : boolean;
    procedure SetFormula (aFormula : string);
    function formula : string;
    function currentChar : char;
    procedure Advance;
    procedure GoBack;
  end;

  TKAParserValueType = (vtFloat, vtString);

  TKAParserOnGetValue = procedure (Sender: TObject; const valueName: string; var Value: Double; out Successfull : boolean) of Object;
  TKAParserOnGetStrValue = procedure (Sender: TObject; const valueName: string; var StrValue: string; out Successfull : boolean) of Object;
  TKAParserOnGetRangeValuesEvent = procedure (const RangeFunction, Func: string; ValueType: TKAParserValueType; ValuesArray : TmArrayOfVariants;  out Successfull : boolean) of object;

  TKAParserOnCalcUserFunction = procedure (Sender: TObject; const Func: string; Parameters: TStringList; var Value: Double; out Successfull : boolean) of object;
  TKAParserOnCalcStrUserFunction = procedure (Sender: TObject; const Func: string; Parameters: TStringList; var Value: string; out Handled: Boolean) of object;


  { TKAParser }

  TKAParser = class
  strict private
    FDecimalNumbers : integer;
    FOnGetValue : TKAParserOnGetValue;
    FOnGetStrValue : TKAParserOnGetStrValue;
    FOnGetRangeValues : TKAParserOnGetRangeValuesEvent;
    FOnCalcUserFunction : TKAParserOnCalcUserFunction;
    FOnCalcStrUserFunction : TKAParserOnCalcStrUserFunction;

    function IsDecimalSeparator (aValue : char) : boolean;
    function IsStringSeparator (aValue : char) : boolean;
    function CleanFormula(aFormula : string) : string;

    function DoInternalCalculate(calculation: TCalculationType; const subFormula: string; var resValue: double) : boolean;
    function DoInternalStringCalculate(calculation: TCalculationType; const subFormula: string; var resValue: string) : boolean;
    function DoInternalRangeCalculate(const RangeFunction, Func: string; ValueType: TKAParserValueType; ValuesArray : TmArrayOfVariants) : boolean;
    function DoUserFunction(const funct: string; ParametersList: TStringList): double;
    function DoStrUserFunction(const funct : string; ParametersList: TStringList) : string;
    // Lexical Analyzer Function http://www.gnu.org/software/bison/manual/html_node/Lexical.html
    procedure yylex (var lexState: TLexState; var lexResult : TLexResult);
    // double
    procedure StartCalculate(var resValue: double; var lexState: TLexState; var lexResult : TLexResult);
    procedure Calc6(var resValue: double; var lexState: TLexState; var lexResult : TLexResult);
    procedure Calc5(var resValue: double; var lexState: TLexState; var lexResult : TLexResult);
    procedure Calc4(var resValue: double; var lexState: TLexState; var lexResult : TLexResult);
    procedure Calc3(var resValue: double; var lexState: TLexState; var lexResult : TLexResult);
    procedure Calc2(var resValue: double; var lexState: TLexState; var lexResult : TLexResult);
    procedure Calc1(var resValue: double; var lexState: TLexState; var lexResult : TLexResult);
    procedure CalcTerm(var resValue: double; var lexState: TLexState; var lexResult : TLexResult);
    // string
    procedure StartCalculateStr(var resValue: string; var lexState: TLexState; var lexResult : TLexResult);
    procedure CalculateStrLevel1(var resValue: string; var lexState: TLexState; var lexResult : TLexResult);
    procedure CalculateStrLevel2(var resValue: string; var lexState: TLexState; var lexResult : TLexResult);
    // range functions
    procedure ManageRangeFunction (const funct: string; ParametersList: TStringList; const ValueType: TKAParserValueType; var TempValuesArray : TmArrayOfVariants);
    function IsInternalFunction(functionName: string): boolean;
    function IsFunction(functionName: string): boolean;
    procedure ParseFunctionParameters(const funct: string; ParametersList: TStringList; var lexState: TLexState);
    function ExecuteFunction(const funct : string; ParametersList : TStringList) : double;
    function ExecuteStrFunction(const funct : string; ParametersList : TStringList) : string;

    function ComposeErrorString (const aErrorCode : integer) : String;
    procedure RaiseError (const aErrorCode : integer); overload;
    procedure RaiseError (const aErrorCode: integer; aErrorMessage : string); overload;

    function FloatToBoolean (aValue : double) : boolean;
    function StrToFloatExt (aValue : string) : double;
    function InternalDoublesAreEqual (aValue1, aValue2 : double) :boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function Calculate(const formula: string; out resValue : double) : boolean;
    function CalculateString(const formula : string; out resValue : string) : boolean;

    class function BooleanToFloat (aValue : boolean) : double;
    class function VariantToFloat (aValue : variant) : double;

    property DecimalNumbers : integer read FDecimalNumbers write FDecimalNumbers; // if -1 it takes the default value from unit mFloatsManagement
    // to extract data values i.e. from a dataset
    property OnGetValue : TKAParserOnGetValue read FOnGetValue write FOnGetValue;
    property OnGetStrValue : TKAParserOnGetStrValue read FOnGetStrValue write FOnGetStrValue;
    property OnGetRangeValues : TKAParserOnGetRangeValuesEvent read FOnGetRangeValues write FOnGetRangeValues;
    // to implement custom function
    property OnCalcUserFunction : TKAParserOnCalcUserFunction read FOnCalcUserFunction write FOnCalcUserFunction;
    property OnCalcStrUserFunction : TKAParserOnCalcStrUserFunction read FOnCalcStrUserFunction write FOnCalcStrUserFunction;
  end;

implementation

uses
  Math, DateUtils,
  mFloatsManagement, mUtility;

{ TKAParser }

class function TKAParser.BooleanToFloat(aValue: boolean): double;
begin
  if aValue then
    Result := 1
  else
    Result := 0;
end;

class function TKAParser.VariantToFloat(aValue: variant): double;
var
  tmpInt : Integer;
begin
  if VarIsNull(aValue) or VarIsEmpty(aValue) then
    Result := 0.0
  else
  begin
    if VarType(aValue) = vardate then
      Result := VarToDateTime(aValue)
    else if VarIsFloat(aValue) then
      Result := aValue
    else if VarIsOrdinal(aValue) then
    begin
      tmpInt := aValue;
      Result := tmpInt;
    end
    else if VarIsBool(aValue) then
      Result := TKAParser.BooleanToFloat(aValue)
    else
      raise TParserException.Create(VarToStr(aValue) + ' is not a valid float');
  end;
end;

procedure TKAParser.Calc1(var resValue: double; var lexState: TLexState; var lexResult: TLexResult);
var
  NewDouble : double;
begin
  CalcTerm(resValue, lexState, lexResult);
  if (lexResult.Token = tkPOW) then
  begin
    yylex(lexState, lexResult);
    CalcTerm(NewDouble, lexState, lexResult);
    resValue := power(resValue, NewDouble);
  end;
end;

procedure TKAParser.Calc2(var resValue: double; var lexState: TLexState; var lexResult: TLexResult);
var
  LastToken: TFormulaToken;
begin
  if (lexResult.Token in [tkNOT, tkINV, tkADD, tkSUB]) then
  begin
    LastToken := lexResult.Token;
    yylex(lexState, lexResult);
    Calc2(resValue, lexState, lexResult);
    case LastToken of
      tkADD: ;
      tkINV: resValue := (not Trunc(resValue));
      tkSUB: resValue := -resValue;
      tkNOT:
        if Trunc(resValue) = 0 then
          resValue := 1
        else
          resValue := 0;
    end;
  end
  else
    Calc1(resValue, lexState, lexResult);
end;

procedure TKAParser.Calc3(var resValue: double; var lexState: TLexState; var lexResult: TLexResult);
var
  NewDouble: double;
  LastToken: TFormulaToken;
begin
  Calc2(resValue, lexState, lexResult);
  while lexResult.Token in [tkMUL, tkDIV, tkMOD, tkPER] do
  begin
    LastToken := lexResult.Token;
    yylex(lexState, lexResult);
    Calc2(NewDouble, lexState, lexResult);
    case LastToken of
      tkPER: resValue := resValue * NewDouble / 100;
      tkMOD: resValue := Trunc(resValue) mod Trunc(NewDouble);
      tkDIV: resValue := resValue / NewDouble;
      tkMUL: resValue := resValue * NewDouble;
    end;
  end;
end;

procedure TKAParser.Calc4(var resValue: double; var lexState: TLexState; var lexResult: TLexResult);
var
  NewDouble: double;
  LastToken: TFormulaToken;
begin
  Calc3(resValue, lexState, lexResult);
  while lexResult.Token in [tkADD, tkSUB] do
  begin
    LastToken := lexResult.Token;
    yylex(lexState, lexResult);
    Calc3(NewDouble, lexState, lexResult);
    case LastToken of
      tkSUB: resValue := resValue - NewDouble;
      tkADD: resValue := resValue + NewDouble;
    end;
  end;
end;

procedure TKAParser.Calc5(var resValue: double; var lexState: TLexState; var lexResult: TLexResult);
var
  NewDouble: double;
  LastToken: TFormulaToken;
begin
  Calc4(resValue, lexState, lexResult);
  while lexResult.Token in [tkLT, tkLE, tkEQ, tkNE, tkGE, tkGT] do
  begin
    LastToken := lexResult.Token;
    yylex(lexState, lexResult);
    Calc4(NewDouble, lexState, lexResult);
    case LastToken of
      tkLT: resValue := BooleanToFloat((not InternalDoublesAreEqual(resValue, NewDouble)) and (resValue < NewDouble));
      tkLE: resValue := BooleanToFloat(InternalDoublesAreEqual(resValue, NewDouble) or (resValue < NewDouble));
      tkEQ: resValue := BooleanToFloat(InternalDoublesAreEqual(resValue, NewDouble));
      tkNE: resValue := BooleanToFloat(not InternalDoublesAreEqual(resValue, NewDouble));
      tkGE: resValue := BooleanToFloat(InternalDoublesAreEqual(resValue, NewDouble) or (resValue > NewDouble));
      tkGT: resValue := BooleanToFloat((not InternalDoublesAreEqual(resValue, NewDouble)) and (resValue > NewDouble));
    end;
  end;
end;

procedure TKAParser.Calc6(var resValue: double; var lexState: TLexState; var lexResult: TLexResult);
var
  NewDouble: double;
  LastToken: TFormulaToken;
begin
  Calc5(resValue, lexState, lexResult);
  while lexResult.Token in [tkOR, tkXOR, tkAND] do
  begin
    LastToken := lexResult.Token;
    yylex(lexState, lexResult);
    Calc5(NewDouble, lexState, lexResult);
    case LastToken of
      tkAND: resValue := Trunc(resValue) and Trunc(NewDouble);
      tkOR : resValue := Trunc(resValue) or  Trunc(NewDouble);
      tkXOR: resValue := Trunc(resValue) xor Trunc(NewDouble);
    end;
  end;
end;

procedure TKAParser.CalculateStrLevel1(var resValue: string; var lexState: TLexState; var lexResult: TLexResult);
var
  newString: string;
begin
  CalculateStrLevel2(resValue, lexState, lexResult);
  while lexResult.Token = tkAdd do
  begin
    yylex(lexState, lexResult);
    CalculateStrLevel2(newString, lexState, lexResult);
    resValue := resValue + newString;
  end;
end;

procedure TKAParser.CalcTerm(var resValue: double; var lexState: TLexState; var lexResult: TLexResult);
var
  currentIdent: String;
  ParamList: TStringList;
begin
  case lexResult.Token of
    tkNUMBER:
    begin
      if lexResult.IsInteger then
        resValue := lexResult.IntValue
      else
        resValue := lexResult.DoubleValue;
      yylex(lexState, lexResult);
    end;
    tkLBRACE:
    begin
      yylex(lexState, lexResult);
      Calc6(resValue, lexState, lexResult);
      if (lexResult.Token = tkRBRACE) then
        yylex(lexState, lexResult)
      else
        RaiseError(sSyntaxError);
    end;
    tkIDENT:
    begin
      currentIdent := lexResult.StringValue;
      yylex(lexState, lexResult);
      if lexResult.Token = tkLBRACE then
      begin
        if IsFunction(currentIdent) then
        begin
          ParamList := TStringList.Create;
          try
            ParseFunctionParameters(currentIdent, ParamList, lexState);
            resValue := ExecuteFunction(currentIdent, ParamList);
          finally
            ParamList.Free;
          end;
          yylex(lexState, lexResult);
        end
        else
        if IsInternalFunction(currentIdent) then
        begin
          yylex(lexState, lexResult);
          Calc6(resValue, lexState, lexResult);
          if (lexResult.Token = tkRBRACE) then
            yylex(lexState, lexResult)
          else
            RaiseError(sFunctionError, currentIdent);
          if not DoInternalCalculate(calculateFunction, currentIdent, resValue) then
            RaiseError(sFunctionError, currentIdent);
        end
        else
        begin
          ParamList := TStringList.Create;
          try
            ParseFunctionParameters(currentIdent, ParamList, lexState);
            resValue := DoUserFunction(currentIdent, ParamList);
          finally
            ParamList.Free;
          end;
          yylex(lexState, lexResult);
        end;
      end
      else
      if not DoInternalCalculate(calculateValue, currentIdent, resValue) then
        RaiseError(sFunctionError, currentIdent);
    end
    else
      RaiseError(sSyntaxError);
  end;
end;

procedure TKAParser.CalculateStrLevel2(var resValue: string; var lexState: TLexState; var lexResult: TLexResult);
var
  currentIdent: String;
  ParamList: TStringList;
begin
  case lexResult.Token of
    tkString:
    begin
      resValue := Copy(lexResult.StringValue, 1, Length(lexResult.StringValue));
      yylex(lexState, lexResult);
    end;
    tkLBrace:
    begin
      yylex(lexState, lexResult);
      CalculateStrLevel1(resValue, lexState, lexResult);
      if lexResult.Token = tkRBRACE then
        yylex(lexState, lexResult)
      else
        RaiseError(sSyntaxError);
    end;
    tkIDENT:
      begin
        currentIdent := lexResult.StringValue;
        yylex(lexState, lexResult);
        if lexResult.Token = tkLBRACE then
        begin
          ParamList := TStringList.Create;
          try
            ParseFunctionParameters(currentIdent, ParamList, lexState);

            if IsFunction(currentIdent) then
              resValue := ExecuteStrFunction(currentIdent, ParamList)
            else
            if ParamList.Count = 1 then
            begin
              Self.CalculateString(ParamList.Strings[0], resValue);
              if not Self.DoInternalStringCalculate(calculateFunction, currentIdent, resValue) then
                resValue := DoStrUserFunction(currentIdent, ParamList);
            end
            else
              resValue := DoStrUserFunction(currentIdent, ParamList);
          finally
            ParamList.Free;
          end;
          yylex(lexState, lexResult);
        end
        else
          if not DoInternalStringCalculate(calculateValue, currentIdent, resValue) then
            RaiseError(SFunctionError, currentIdent);
      end;
    else
      RaiseError(SSyntaxError);
  end;
end;

function TKAParser.CleanFormula(aFormula: string): string;
begin
  Result := trim(aFormula);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
end;

function TKAParser.Calculate(const formula: string; out resValue: double): boolean;
var
  newFormula : string;
  LexState : TLexState;
  LexResult : TLexResult;
begin
  newFormula := CleanFormula(formula);

  LexState.SetFormula(newFormula);

  yylex(LexState, LexResult);

  StartCalculate(resValue, lexState, LexResult);

  Result := true;
end;

function TKAParser.CalculateString(const formula: string; out resValue: string): boolean;
var
  newFormula : string;
  LexState : TLexState;
  LexResult : TLexResult;
begin
  newFormula := CleanFormula(formula);

  LexState.SetFormula(newFormula);

  yylex(LexState, LexResult);

  StartCalculateStr(resValue, lexState, LexResult);

  Result := true;
end;

constructor TKAParser.Create;
begin
  FDecimalNumbers := -1;
  FOnGetValue := nil;
  FOnGetStrValue := nil;
  FOnGetRangeValues := nil;
  FOnCalcUserFunction := nil;
  FOnCalcStrUserFunction := nil;
end;

destructor TKAParser.Destroy;
begin

  inherited;
end;

function TKAParser.DoInternalCalculate(calculation: TCalculationType; const subFormula: string; var resValue: double): boolean;
begin
  if calculation = calculateValue then
  begin
    Result := true;
    if CompareText(subFormula, mP_intconst_now) = 0 then
      resValue := Now
    else
    if CompareText(subFormula, mP_intconst_today) = 0 then
      resValue := Date
    else
    if CompareText(subFormula, mP_intconst_true) = 0 then
      resValue := 1
    else
    if CompareText(subFormula, mP_intconst_false) = 0 then
      resValue := 0
    else
    if CompareText(subFormula, mP_intconst_pi) = 0 then
      resValue := Pi
    else
    begin
      if Assigned(FOnGetValue) then
        FOnGetValue(Self, subFormula, resValue, Result)
      else
        Result := false;
    end;
  end
  else // calculation = calculateFunction
  begin
    Result := true;
    if compareText(subFormula, mP_intfunc_trunc) = 0 then
      resValue := trunc(resValue)
    else
    if compareText(subFormula, mP_intfunc_sin) = 0 then
      resValue := sin(resValue)
    else
    if compareText(subFormula, mP_intfunc_cos) = 0 then
      resValue := cos(resValue)
    else
    if compareText(subFormula, mP_intfunc_tan) = 0 then
      resValue := tan(resValue)
    else
    if compareText(subFormula, mP_intfunc_frac) = 0 then
      resValue := frac(resValue)
    else
    if compareText(subFormula, mP_intfunc_int) = 0 then
      resValue := int(resValue)
    else
    begin
      if Assigned(FOnGetValue) then
        FOnGetValue(Self, subFormula, resValue, Result)
      else
        Result := false;
    end;
  end;
end;

function TKAParser.DoInternalRangeCalculate(const RangeFunction, Func: string; ValueType: TKAParserValueType; ValuesArray : TmArrayOfVariants): boolean;
begin
  if Assigned (FOnGetRangeValues) then
    FOnGetRangeValues(RangeFunction, Func, ValueType, ValuesArray, Result)
  else
    Result := false;
end;

function TKAParser.DoInternalStringCalculate(calculation: TCalculationType; const subFormula: string; var resValue: string): boolean;
begin
  Result := false;
  if calculation = calculateFunction then
  begin
    if CompareText(subFormula, mp_specfunc_trim) = 0 then
      resValue := trim(resValue)
    else
    if CompareText(subFormula, mp_specfunc_ltrim) = 0 then
      resValue := TrimLeft(resValue)
    else
    if CompareText(subFormula, mp_specfunc_rtrim) = 0 then
      resValue := TrimRight(resValue)
    else
    begin
      if Assigned(FOnGetStrValue) then
        FOnGetStrValue(Self, subFormula, resValue, Result)
      else
        Result := false;
    end;
  end;
end;

function TKAParser.DoStrUserFunction(const funct: string; ParametersList: TStringList): string;
var
  TempSucc : boolean;
begin
  TempSucc := false;
  if Assigned(FOnCalcStrUserFunction) then
    FOnCalcStrUserFunction(Self, funct, ParametersList, Result, TempSucc);

  if not TempSucc then
    RaiseError(sFunctionError, funct);
end;

function TKAParser.DoUserFunction(const funct: string; ParametersList: TStringList): double;
var
  TempSucc : boolean;
begin
  TempSucc := false;
  if Assigned(FOnCalcUserFunction) then
    FOnCalcUserFunction(Self, funct, ParametersList, Result, TempSucc);

  if not TempSucc then
    RaiseError(sFunctionError, funct);
end;

function TKAParser.ExecuteFunction(const funct: string; ParametersList: TStringList) : double;
var
  TempStrValue, TempStrValue2 : string;
  TempDouble, TempDouble2, TempDouble3 : double;
  TempDouble4, TempDouble5, TempDouble6 : double;
  TempBoolean : boolean;
  i : integer;
  TempDoubleArray : TmArrayOfVariants;
begin
  Result := 0.0;

  if CompareText(funct, mp_specfunc_if) = 0 then
  begin
    if ParametersList.Count <> 3 then
      RaiseError(sWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], Result);
    if Result <> 0 then
      Self.Calculate(ParametersList.Strings[1], Result)
    else
      Self.Calculate(ParametersList.Strings[2], Result);
  end
  else
  if CompareText(funct, mp_specfunc_len) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(sWrongParamCount);
    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Result := Length(TempStrValue);
  end
  else
  if CompareText(funct, mp_specfunc_pos) = 0 then
  begin
    if ParametersList.Count <> 2 then
      RaiseError(sWrongParamCount);
    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Self.CalculateString(ParametersList.Strings[1], TempStrValue2);
    Result := Pos(TempStrValue, TempStrValue2);
  end
  else
  if (CompareText(funct, mp_specfunc_todouble) = 0) then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(sWrongParamCount);
    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Result := StrToFloatExt(TempStrValue);
  end
  else
  if CompareText(funct, mp_specfunc_today) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(sWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := Date - TempDouble;
  end
  else
  if CompareText(funct, mp_specfunc_now) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(sWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := Now - TempDouble;
  end
  else
  if CompareText(funct, mp_specfunc_getday) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(sWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := DayOfTheMonth(TempDouble);
  end
  else
  if CompareText(funct, mp_specfunc_getyear) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := YearOf(TempDouble);
  end
  else
  if CompareText(funct, mp_specfunc_getweek) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := WeekOfTheYear(TempDouble);
  end
  else
  if CompareText(funct, mp_specfunc_getmonth) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := MonthOfTheYear(TempDouble);
  end
  else
  if CompareText(funct, mp_specfunc_startoftheweek) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := StartOfTheWeek(TempDouble);
  end
  else
  if CompareText(funct, mp_specfunc_startofthemonth) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := StartOfTheMonth(TempDouble);
  end
  else
  if CompareText(funct, mp_specfunc_endofthemonth) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := EndOfTheMonth(TempDouble);
  end
  else
  if (CompareText(funct, mp_specfunc_todate)=0)  then
  begin
    if ParametersList.Count <> 3 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Self.Calculate(ParametersList.Strings[1], TempDouble2);
    Self.Calculate(ParametersList.Strings[2], TempDouble3);
    Result := EncodeDate(round(TempDouble), round(TempDouble2), round(TempDouble3));
  end
  else
  if (CompareText(funct, mp_specfunc_todatetime)=0) then
  begin
    if ParametersList.Count <> 6 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Self.Calculate(ParametersList.Strings[1], TempDouble2);
    Self.Calculate(ParametersList.Strings[2], TempDouble3);
    Self.Calculate(ParametersList.Strings[3], TempDouble4);
    Self.Calculate(ParametersList.Strings[4], TempDouble5);
    Self.Calculate(ParametersList.Strings[5], TempDouble6);
    Result := EncodeDateTime(round(TempDouble), round(TempDouble2), round(TempDouble3), round(TempDouble4), round(TempDouble5), round(TempDouble6), 0);
  end
  else
  if CompareText(funct, mp_specfunc_empty) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(sWrongParamCount);
    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Result := BooleanToFloat(Length(Trim(TempStrValue)) = 0);
  end
  else
  if CompareText(funct, mp_specfunc_compare) = 0 then
  begin
    if ParametersList.Count <> 2 then
      RaiseError(sWrongParamCount);
    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Self.CalculateString(ParametersList.Strings[1], TempStrValue2);
    Result := BooleanToFloat(CompareStr(TempStrValue, TempStrValue2) = 0);
  end
  else
  if CompareText(funct, mp_specfunc_comparestr) = 0 then
  begin
    if ParametersList.Count <> 2 then
      RaiseError(sWrongParamCount);
    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Self.CalculateString(ParametersList.Strings[1], TempStrValue2);
    Result := CompareStr(TempStrValue, TempStrValue2);
  end
  else
  if CompareText(funct, mp_specfunc_comparetext) = 0 then
  begin
    if ParametersList.Count <> 2 then
      RaiseError(sWrongParamCount);
    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Self.CalculateString(ParametersList.Strings[1], TempStrValue2);
    Result := CompareText(TempStrValue, TempStrValue2);
  end
  else
  if CompareText(funct,mp_specfunc_and) = 0 then
  begin
    if ParametersList.Count < 2 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    TempBoolean := Self.FloatToBoolean(TempDouble);
    if TempBoolean then
    begin
      for i := 1 to ParametersList.Count - 1 do
      begin
        Self.Calculate(ParametersList.Strings[i], TempDouble);
        TempBoolean := TempBoolean and Self.FloatToBoolean(TempDouble);
        if not TempBoolean then
          break;
      end;
    end;
    Result := BooleanToFloat(TempBoolean);
  end
  else
  if CompareText(funct,mp_specfunc_or) = 0 then
  begin
    if ParametersList.Count < 2 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    TempBoolean := Self.FloatToBoolean(TempDouble);
    if not TempBoolean then
    begin
      for i := 1 to ParametersList.Count - 1 do
      begin
        Self.Calculate(ParametersList.Strings[i], TempDouble);
        TempBoolean := TempBoolean or Self.FloatToBoolean(TempDouble);
        if TempBoolean then
          break;
      end;
    end;
    Result := BooleanToFloat(TempBoolean);
  end
  else
  if CompareText(funct, mp_specfunc_safediv) = 0 then
  begin
    if ParametersList.Count <> 2 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Self.Calculate(ParametersList.Strings[1], TempDouble2);
    Result:= SafeDiv(TempDouble, TempDouble2);
  end
  else
  if CompareText(funct, mp_specfunc_between) = 0 then
  begin
    if ParametersList.Count <> 3 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Self.Calculate(ParametersList.Strings[1], TempDouble2);
    Self.Calculate(ParametersList.Strings[2], TempDouble3);

    Result := BooleanToFloat(
      Self.InternalDoublesAreEqual(TempDouble, TempDouble2) or
      Self.InternalDoublesAreEqual(TempDouble, TempDouble3) or
      ((TempDouble >= TempDouble2) and (TempDouble <= TempDouble3)));
  end
  else
  if CompareText(funct, mp_specfunc_round) = 0 then
  begin
    if ParametersList.Count <> 2 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Self.Calculate(ParametersList.Strings[1], TempDouble2);

    Result := StrToFloat(Format('%.*f', [Round(TempDouble2), TempDouble]));
  end
  else
  if CompareText(funct, mp_specfunc_ceil) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := Math.Ceil(TempDouble);
  end
  else
  if CompareText(funct, mp_specfunc_floor) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    Result := Math.Floor(TempDouble);
  end
  else
  if CompareText(funct, mp_specfunc_stringtodatetime) = 0 then
  begin
    if ParametersList.Count <> 2 then
      RaiseError(SWrongParamCount);
    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Self.CalculateString(ParametersList.Strings[1], TempStrValue2);
    Result := DateTimeStrEval(TempStrValue2, TempStrValue);
  end
  else
  if CompareText(funct, mp_specfunc_not) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);
    Self.Calculate(ParametersList.Strings[0], TempDouble);
    if FloatToBoolean(TempDouble) then
      Result := 0
    else
      Result := 1;
  end
  else
  if CompareText(funct, mp_specfunc_sum) = 0 then
  begin
    if ParametersList.Count < 1 then
      RaiseError(SWrongParamCount);
    ManageRangeFunction(funct, ParametersList, vtFloat, TempDoubleArray);

    TempDouble := 0;
    for i := 0 to length(TempDoubleArray) - 1 do
    begin
      TempDouble := TempDouble + TempDoubleArray[i];
    end;
    Result := TempDouble;
  end
  else
  if CompareText(funct, mp_specfunc_max) = 0 then
  begin
    if ParametersList.Count < 1 then
      RaiseError(SWrongParamCount);

    ManageRangeFunction(funct, ParametersList, vtFloat, TempDoubleArray);

    if length(TempDoubleArray) = 0 then
      Result := 0
    else
    begin
      TempDouble := TempDoubleArray[0];
      for i := 1 to length(TempDoubleArray) - 1 do
      begin
        TempDouble := max(TempDouble, TempDoubleArray[i]);
      end;
      Result := TempDouble;
    end;
  end
  else
  if CompareText(funct, mp_specfunc_min) = 0 then
  begin
    if ParametersList.Count < 1 then
      RaiseError(SWrongParamCount);

    ManageRangeFunction(funct, ParametersList, vtFloat, TempDoubleArray);

    if length(TempDoubleArray) = 0 then
      Result := 0
    else
    begin
      TempDouble := TempDoubleArray[0];
      for i := 1 to length(TempDoubleArray) - 1 do
      begin
        TempDouble := min(TempDouble, TempDoubleArray[i]);
      end;
      Result := TempDouble;
    end;
  end
  else
  if CompareText(funct, mp_specfunc_avg) = 0 then
  begin
    if ParametersList.Count < 1 then
      RaiseError(SWrongParamCount);

    ManageRangeFunction(funct, ParametersList, vtFloat, TempDoubleArray);

    TempDouble := 0;
    for i := 0 to length(TempDoubleArray) - 1 do
    begin
      TempDouble := TempDouble + TempDoubleArray[i];
    end;
    if length(TempDoubleArray) > 0 then
      Result := TempDouble / length(TempDoubleArray)
    else
      Result := 0;
  end
  else
  if CompareText(funct, mp_specfunc_count) = 0 then
  begin
    if ParametersList.Count < 1 then
      RaiseError(SWrongParamCount);

    ManageRangeFunction(funct, ParametersList, vtFloat, TempDoubleArray);

    Result := length(TempDoubleArray);
  end;
end;

function TKAParser.ExecuteStrFunction(const funct: string; ParametersList: TStringList): string;
var
  TempStrValue : string;
  TempValue, TempValue2 : double;
  i: integer;
  TempStrArray : TmArrayOfVariants;
begin
  Result := '';

  if CompareText(funct, mp_specfunc_if) = 0 then
  begin
    if ParametersList.Count <> 3 then
      RaiseError(SWrongParamCount);

    Self.Calculate(ParametersList.Strings[0], TempValue);

    if InternalDoublesAreEqual(1, TempValue) or (TempValue > 1) then
      Self.CalculateString(ParametersList.Strings[1], TempStrValue)
    else
      Self.CalculateString(ParametersList.Strings[2], TempStrValue);

    Result := TempStrValue;
  end
  else
  if CompareText(funct, mp_specfunc_repl) = 0 then
  begin
    if ParametersList.Count <> 3 then
      RaiseError(SWrongParamCount);

    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Result := TempStrValue;
	Self.Calculate(ParametersList.Strings[1], TempValue);
    for i := 1 to Round(TempValue) do
      Result := Result + TempStrValue;
  end
  else
  if (CompareText(funct, mp_specfunc_concatenate) = 0) or
    (CompareText(funct, mp_specfunc_concat) = 0) then
  begin
    if ParametersList.Count < 2 then
      RaiseError(SWrongParamCount);

    Result := '';
    for i := 0 to ParametersList.Count - 1 do
    begin
      Self.CalculateString(ParametersList.Strings[i], TempStrValue);
      Result := Result + TempStrValue;
    end;
  end
  else
  if CompareText(funct, mp_specfunc_tostr) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);

    Self.Calculate(ParametersList.Strings[0], TempValue);
    Result := FloatToStr(TempValue);
  end
  else
  if CompareText(funct, mp_specfunc_uppercase) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);

    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Result := Uppercase(TempStrValue);
  end
  else
  if CompareText(funct, mp_specfunc_lowercase) = 0 then
  begin
    if ParametersList.Count <> 1 then
      RaiseError(SWrongParamCount);

    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Result := LowerCase(TempStrValue);
  end
  else
  if CompareText(funct, mp_specfunc_left) = 0 then
  begin
    if ParametersList.Count <> 2 then
      RaiseError(SWrongParamCount);

    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Self.Calculate(ParametersList.Strings[1], TempValue);
    Result := Copy(TempStrValue, 1, Round(TempValue));
  end
  else
  if CompareText(funct, mp_specfunc_right) = 0 then
  begin
    if ParametersList.Count <> 2 then
      RaiseError(SWrongParamCount);

    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Self.Calculate(ParametersList.Strings[1], TempValue);
    Result := Copy(TempStrValue, Length(TempStrValue) - Round(TempValue) + 1, Length(TempStrValue));
  end
  else
  if CompareText(funct, mp_specfunc_substr) = 0 then
  begin
    if ParametersList.Count <> 3 then
      RaiseError(SWrongParamCount);

    Self.CalculateString(ParametersList.Strings[0], TempStrValue);
    Self.Calculate(ParametersList.Strings[1], TempValue);
    Self.Calculate(ParametersList.Strings[2], TempValue2);
    Result := Copy(TempStrValue, round(TempValue), round(TempValue2));
  end
  else
  if CompareText(funct, mp_specfunc_sum) = 0 then
  begin
    ManageRangeFunction(funct,ParametersList, vtString, TempStrArray);
    Result := '';
    for i := 0 to length(TempStrArray) - 1 do
    begin
      Result := Result + TempStrArray[i];
    end;
  end
  else
  if CompareText(funct, mp_specfunc_max) = 0 then
  begin
    ManageRangeFunction(funct,ParametersList, vtString, TempStrArray);
    Result := '';
    for i := 0 to length(TempStrArray) - 1 do
    begin
      if Result < TempStrArray[i] then
        Result := TempStrArray[i];
    end;
  end
  else
  if CompareText(funct, mp_specfunc_min) = 0 then
  begin
    ManageRangeFunction(funct,ParametersList, vtString, TempStrArray);
    Result := '';
    for i := 0 to length(TempStrArray) - 1 do
    begin
      if Result > TempStrArray[i] then
        Result := TempStrArray[i];
    end;
  end
  else
  if CompareText(funct, mp_specfunc_count) = 0 then
  begin
    ManageRangeFunction(funct,ParametersList, vtString, TempStrArray);
    Result := IntToStr(length(TempStrArray));
  end;
end;

function TKAParser.ComposeErrorString(const aErrorCode: integer): String;
begin
  Result := 'Error ' + IntToStr(aErrorCode);
  if aErrorCode = sInvalidString then
    Result := Result + ': invalid string.'
  else if aErrorCode = sSyntaxError then
    Result := Result + ': syntax error.'
  else if aErrorCode = sFunctionError then
    Result := Result + ': function error.'
  else if aErrorCode =sWrongParamCount then
    Result := Result + ': wrong number of parameters.';
end;

function TKAParser.FloatToBoolean(aValue: double): boolean;
begin
  Result := (round(Abs(aValue)) >= 1);
end;

function TKAParser.InternalDoublesAreEqual(aValue1, aValue2: double): boolean;
begin
  if FDecimalNumbers >= 0 then
    Result := DoublesAreEqual(aValue1, aValue2, FDecimalNumbers)
  else
    Result := DoublesAreEqual(aValue1, aValue2)
end;

function TKAParser.IsInternalFunction(functionName: string): boolean;
var
  temp : string;
begin
  temp := LowerCase(functionName);
  Result := (temp=mP_intfunc_trunc) or (temp=mP_intfunc_sin) or (temp=mP_intfunc_cos) or (temp=mP_intfunc_tan) or
    (temp=mP_intfunc_frac) or (temp=mP_intfunc_int);
end;


function TKAParser.IsDecimalSeparator(aValue: char): boolean;
begin
  Result := (aValue = '.') or (aValue = ',');
end;

function TKAParser.IsStringSeparator(aValue: char): boolean;
begin
  Result := (aValue = '''') or (aValue = '"');
end;

function TKAParser.IsFunction(functionName: string): boolean;
var
  temp : string;
begin
  temp := LowerCase(functionName);
  Result := (temp = mp_specfunc_if) or
    (temp = mp_specfunc_empty) or
    (temp = mp_specfunc_len) or
    (temp = mp_specfunc_and) or
    (temp = mp_specfunc_or) or
    (temp = mp_specfunc_safediv) or
    (temp = mp_specfunc_between) or
    (temp = mp_specfunc_concatenate) or
    (temp = mp_specfunc_concat) or
    (temp = mp_specfunc_repl) or
    (temp = mp_specfunc_left) or
    (temp = mp_specfunc_right) or
    (temp = mp_specfunc_substr) or
    (temp = mp_specfunc_tostr) or
    (temp = mp_specfunc_pos) or
    (temp = mp_specfunc_trim) or
    (temp = mp_specfunc_ltrim) or
    (temp = mp_specfunc_rtrim) or
    (temp = mp_specfunc_uppercase) or
    (temp = mp_specfunc_lowercase) or
    (temp = mp_specfunc_compare) or
    (temp = mp_specfunc_comparestr) or
    (temp = mp_specfunc_comparetext) or
    (temp = mp_specfunc_round) or
    (temp = mp_specfunc_ceil) or
    (temp = mp_specfunc_floor) or
    (temp = mp_specfunc_not) or
    (temp = mp_specfunc_sum) or
    (temp = mp_specfunc_max) or
    (temp = mp_specfunc_min) or
    (temp = mp_specfunc_avg) or
    (temp = mp_specfunc_count) or
    (temp = mp_specfunc_now) or
    (temp = mp_specfunc_getday) or
    (temp = mp_specfunc_getweek) or
    (temp = mp_specfunc_getmonth) or
    (temp = mp_specfunc_getyear) or
    (temp = mp_specfunc_startoftheweek) or
    (temp = mp_specfunc_startofthemonth) or
    (temp = mp_specfunc_endofthemonth) or
    (temp = mp_specfunc_todate) or
    (temp = mp_specfunc_todatetime) or
    (temp = mp_specfunc_now) or
    (temp = mp_specfunc_today) or
    (temp = mp_specfunc_stringtodatetime) or
    (temp = mp_specfunc_todouble);

end;

procedure TKAParser.ParseFunctionParameters(const funct: string; ParametersList: TStringList; var lexState: TLexState);
var
  startindex, i, q, k, par : integer;
  parametersStr, str : string;
  insideCommas : boolean;
  currentStringSeparator : String;
begin
  // this function must find the first "(" and then go forward
  // opening and closing all the parentesis
  // until it finds the closed ")" that match with the first found

  startindex := lexState.FCharIndex;
  par := 1;
  insideCommas:= false;
  currentStringSeparator := '';

  while not lexState.IsEof do
  begin
    if IsStringSeparator(lexState.FFormula[lexState.FCharIndex]) and ((currentStringSeparator = '') or (currentStringSeparator = lexState.FFormula[lexState.FCharIndex])) then
    begin
      insideCommas:= not insideCommas;
      if insideCommas then
        currentStringSeparator:= lexState.FFormula[lexState.FCharIndex]
      else
        currentStringSeparator:= '';
    end
    else if (not insideCommas) and (lexState.FFormula[lexState.FCharIndex] = '(') then
      Inc(par)
    else if (not insideCommas) and (lexState.FFormula[lexState.FCharIndex] = ')') then
      Dec(par);
    if par = 0 then
      break
    else
      lexState.Advance;
  end;

  parametersStr := Trim(Copy(lexState.FFormula, startindex, lexState.FCharIndex - startindex));

  if par <> 0 then
    RaiseError(SFunctionError, funct);
  if parametersStr = '' then
    exit; // no parameters

  lexState.Advance; // let's go to the next char

  par := 0;
  i := 1;
  q := 1;
  k := 0;
  insideCommas := false;
  currentStringSeparator:= '';

  while i <= Length(parametersStr) do
  begin
    if IsStringSeparator(parametersStr[i]) and ((currentStringSeparator = '') or (currentStringSeparator = parametersStr[i])) then
    begin
      insideCommas:= not insideCommas;
      if insideCommas then
        currentStringSeparator:= parametersStr[i]
      else
        currentStringSeparator:= '';
    end;
    if (not insideCommas) and (parametersStr[i] = '(') then
      inc (par)
    else
    if (not insideCommas) and (parametersStr[i] = ')') then
      dec (par);
    if (not insideCommas) and (parametersStr[i]=',') and (par = 0) then
    begin
      str := Trim(Copy(parametersStr, q, k));
      ParametersList.Add(str); //i-1
      q := i + 1;
      k := 0;
    end
    else
      inc(k);
    inc (i);
  end;
  ParametersList.Add(Trim(Copy(parametersStr, q, Length(parametersStr))));
end;

procedure TKAParser.RaiseError(const aErrorCode: integer; aErrorMessage: string);
begin
  raise TParserException.Create(ComposeErrorString(aErrorCode) + ' ' + aErrorMessage);
end;

procedure TKAParser.RaiseError(const aErrorCode: integer);
begin
  raise TParserException.Create(ComposeErrorString(aErrorCode));
end;

procedure TKAParser.StartCalculate(var resValue: double; var lexState: TLexState; var lexResult : TLexResult);
begin
  Calc6(resValue, lexState, lexResult);
  while (lexResult.Token = tkSEMICOLON) do
  begin
    yylex(lexstate, lexResult);
    Calc6(resValue, lexState, lexResult);
  end;
  if not (lexResult.Token = tkEOF) then
    RaiseError(sSyntaxError);
end;

procedure TKAParser.StartCalculateStr(var resValue: string; var lexState: TLexState; var lexResult: TLexResult);
begin
  CalculateStrLevel1(resValue, lexState, lexResult);
  while (lexResult.Token = tkSEMICOLON) do
  begin
    yylex(lexstate, lexResult);
    CalculateStrLevel1(resValue, lexState, lexResult);
  end;
  if not (lexResult.Token = tkEOF) then
    RaiseError(sSyntaxError);
end;

function TKAParser.StrToFloatExt(aValue: string): double;
var
  Dummy : string;
  Riprova : boolean;
begin
  Result := 0;
  try
    Riprova := false;
    try
      Result := StrToFloat(aValue);
      exit;
    except
      Dummy := aValue;
      if FormatSettings.DecimalSeparator = '.'  then
      begin
        Dummy := StringReplace(Dummy, '.', '', [rfReplaceAll]);
        Dummy := StringReplace(Dummy, ',', '.', [rfReplaceAll]);
      end
      else
      begin
        Dummy := StringReplace(Dummy, ',', '', [rfReplaceAll]);
        Dummy := StringReplace(Dummy, '.', ',', [rfReplaceAll]);
      end;
      Riprova := true;
    end;
    if Riprova then
      Result := StrToFloat(Dummy);
  except
    RaiseError(0, Format('%s is not a valid number', [Dummy]));
  end;
end;

procedure TKAParser.yylex(var lexState: TLexState; var lexResult : TLexResult);
var
  currentIntegerStr : string;
  currentInteger : integer;
  currentFloat, decimal : double;
  currentString : string;
  currentStringSeparator : char;
  opChar : char;
begin
  lexResult.Clear;

  if lexState.IsEof then
  begin
    lexResult.Token := tkEOF;
    exit;
  end;

  while (lexState.CurrentChar = ' ') and (not lexState.IsEof) do
    lexState.Advance;

  if lexState.IsEof then
  begin
    lexResult.Token := tkEOF;
    exit;
  end;
  // ------------ forse un numero..

  if CharInSet(lexState.CurrentChar, ['0'..'9']) then
  begin

    currentIntegerStr := lexState.CurrentChar;
    lexState.Advance;

    while (not lexState.IsEof) and CharInSet(lexState.currentChar, ['0'..'9']) do
    begin
      currentIntegerStr := currentIntegerStr + lexState.currentChar;
      lexState.Advance;
    end;

    if not TryStrToInt(currentIntegerStr, currentInteger) then
    begin
      lexResult.Token := tkERROR;
      exit;
    end;

    if (not lexState.IsEof) and IsDecimalSeparator(lexState.currentChar) then
    begin
      lexState.Advance;
      currentFloat := currentInteger;

      decimal := 1;
      while (not lexState.IsEof) and CharInSet(lexState.currentChar, ['0'..'9']) do
      begin
        decimal := decimal / 10;
        currentFloat := currentFloat + (decimal * StrToInt(lexState.currentChar));
        lexState.Advance;
      end;

      lexResult.SetDouble(currentFloat);
    end
    else
    begin
      lexResult.SetInteger(currentInteger);
    end;

    exit;
  end;

  // ------------ forse una stringa..

  if IsStringSeparator(lexState.CurrentChar) then
  begin

    currentString := '';
    currentStringSeparator := lexState.CurrentChar;

    lexState.Advance;

    while true do
    begin
      if lexState.IsEof then
      begin
        RaiseError(sInvalidString);
        exit;
      end;
      if lexState.currentChar = currentStringSeparator then
      begin
        break;
      end
      else
        currentString := currentString + lexState.currentChar;
      lexState.Advance;
    end;

    lexState.Advance;
    lexResult.SetString(currentString);
    exit;
  end;

  // ------------ forse un identificatore..

  if CharInSet(lexState.CurrentChar, ['A'..'Z','a'..'z','_', '@']) then
  begin
    currentString := lexState.CurrentChar;
    lexState.Advance;

    while (not lexState.IsEof) and CharInSet(lexState.currentChar, ['A'..'Z','a'..'z','0'..'9','_', '@']) do
    begin
      currentString := currentString + lexState.currentChar;
      lexState.Advance;
    end;

    lexResult.SetString(currentString);
    lexResult.Token := tkIDENT;
    exit;
  end;

  // ------------ forse un operatore..

  opChar := lexState.currentChar;
  lexState.Advance;
  case opChar of
    '=':
      begin
        if (not lexState.IsEof) and (lexState.currentChar = '=') then
        begin
          lexState.Advance;
          lexResult.Token := tkEQ;
        end
        else
          lexResult.Token := tkERROR;
      end;
    '+':
      begin
        lexResult.Token := tkADD;
      end;
    '-':
      begin
        lexResult.Token := tkSUB;
      end;
    '*':
      begin
        if (not lexState.IsEof) and (lexState.currentChar = '*') then
        begin
          lexState.Advance;
          lexResult.Token := tkPOW;
        end
        else
          lexResult.Token := tkMUL;
      end;
    '/':
      begin
        lexResult.Token := tkDIV;
      end;
    '%':
      begin
        if (not lexState.IsEof) and (lexState.currentChar = '%') then
        begin
          lexState.Advance;
          lexResult.Token := tkPER;
        end
        else
          lexResult.Token := tkMOD;
      end;
    '~':
      begin
        lexResult.Token := tkINV;
      end;
    '^':
      begin
        lexResult.Token := tkXOR;
      end;
    '&':
      begin
        lexResult.Token := tkAND;
      end;
    '|':
      begin
        lexResult.Token := tkOR;
      end;
    '<':
      begin
        if (not lexState.IsEof) and (lexState.currentChar = '=') then
        begin
          lexState.Advance;
          lexResult.Token := tkLE;
        end
        else
        if (not lexState.IsEof) and (lexState.currentChar = '>') then
        begin
          lexState.Advance;
          lexResult.Token := tkNE;
        end
        else
          lexResult.Token := tkLT;
      end;
    '>':
      begin
        if (not lexState.IsEof) and (lexState.currentChar = '=') then
        begin
          lexState.Advance;
          lexResult.Token := tkGE;
        end
        else
        if (not lexState.IsEof) and (lexState.currentChar = '<') then
        begin
          lexState.Advance;
          lexResult.Token := tkNE;
        end
        else
          lexResult.Token := tkGT;
      end;
    '!':
      begin
        if (not lexState.IsEof) and (lexState.currentChar = '=') then
        begin
          lexState.Advance;
          lexResult.Token := tkNE;
        end
        else
          lexResult.Token := tkNOT;
      end;
    '(':
      begin
         lexResult.Token := tkLBRACE;
      end;
    ')':
      begin
        lexResult.Token := tkRBRACE;
      end;
    ';':
      begin
        lexResult.Token := tkSEMICOLON
      end;
    else
    begin
      lexResult.Token := tkERROR;
      lexState.GoBack;
    end;
  end;

end;

procedure TKAParser.ManageRangeFunction (const funct: string; ParametersList: TStringList; const ValueType: TKAParserValueType; var TempValuesArray : TmArrayOfVariants);

  function InsideBraces (aValue : string) : string;
  var
    len : integer;
  begin
    Result := '';
    aValue := trim(aValue);
    len := Length(aValue);

    if len <= 2 then
      RaiseError(sSyntaxError);  // strina vuota o '()'

    if aValue[1] <> '(' then
      RaiseError(sSyntaxError);  // non inizia con '('

    if aValue[len] <> ')' then
      RaiseError(sSyntaxError);  // non finisce con ')'

    Result := Trim(Copy(aValue, 2, len - 2));
  end;
var
  lowercaseFunct : string;
  k : integer;
  TempDouble : double;
  TempString : string;
begin
  SetLength(TempValuesArray, 0);

  if ParametersList.Count = 1 then
  begin
    lowercaseFunct := LowerCase(funct);
    k := Pos(mp_rangefunc_childsnotnull, lowercaseFunct);
    if k >= 1 then
    begin
      TempString := Copy(funct, k + length(mp_rangefunc_childsnotnull), length(funct));
      DoInternalRangeCalculate(mp_rangefunc_childsnotnull, InsideBraces(TempString), ValueType, TempValuesArray);
      exit;
    end;
    k := Pos(mp_rangefunc_parentnotnull, lowercaseFunct);
    if k >= 1 then
    begin
      TempString := Copy(funct, k + length(mp_rangefunc_childsnotnull), length(funct));
      DoInternalRangeCalculate(mp_rangefunc_childsnotnull, InsideBraces(TempString), ValueType, TempValuesArray);
      exit;
    end;
    k := Pos(mp_rangefunc_parentsnotnull, lowercaseFunct);
    if k >= 1 then
    begin
      TempString := Copy(funct, k + length(mp_rangefunc_childsnotnull), length(funct));
      DoInternalRangeCalculate(mp_rangefunc_childsnotnull, InsideBraces(TempString), ValueType, TempValuesArray);
      exit;
    end;
    k := Pos(mp_rangefunc_childs, lowercaseFunct);
    if k >= 1 then
    begin
      TempString := Copy(funct, k + length(mp_rangefunc_childsnotnull), length(funct));
      DoInternalRangeCalculate(mp_rangefunc_childsnotnull, InsideBraces(TempString), ValueType, TempValuesArray);
      exit;
    end;

    k := Pos(mp_rangefunc_parents, lowercaseFunct);
    if k >= 1 then
    begin
      TempString := Copy(funct, k + length(mp_rangefunc_childsnotnull), length(funct));
      DoInternalRangeCalculate(mp_rangefunc_childsnotnull, InsideBraces(TempString), ValueType, TempValuesArray);
      exit;
    end;

    k := Pos(mp_rangefunc_parent, lowercaseFunct);
    if k >= 1 then
    begin
      TempString := Copy(funct, k + length(mp_rangefunc_childsnotnull), length(funct));
      DoInternalRangeCalculate(mp_rangefunc_childsnotnull, InsideBraces(TempString), ValueType, TempValuesArray);
      exit;
    end;
  end;

  SetLength(TempValuesArray, ParametersList.Count);
  for k := 0 to ParametersList.Count - 1 do
  begin
    if ValueType = vtFloat then
    begin
      Self.Calculate(ParametersList.Strings[k], TempDouble);
      TempValuesArray[k] := TempDouble;
    end
    else
    begin
      Self.CalculateString(ParametersList.Strings[k], TempString);
      TempValuesArray[k] := TempString;
    end;
  end;
end;


{ TLexResult }

procedure TLexResult.Clear;
begin
  FIsUndefined := true;
  Token := tkUndefined;
end;

function TLexResult.IsDouble: boolean;
begin
  Result := FIsDouble;
end;

function TLexResult.IsInteger: boolean;
begin
  Result := FIsInteger;
end;

function TLexResult.IsString: boolean;
begin
  Result := (not FIsInteger) and (not FIsDouble) and (not FIsUndefined);
end;

function TLexResult.IsUndefined: boolean;
begin
  Result := FIsUndefined;
end;

procedure TLexResult.SetDouble(aValue: double);
begin
  FIsDouble := true;
  FIsUndefined := false;
  FIsInteger := false;
  Token := tkNUMBER;
  DoubleValue := aValue;
end;

procedure TLexResult.SetInteger(aValue: integer);
begin
  FIsDouble := false;
  FIsUndefined := false;
  FIsInteger := true;
  Token := tkNUMBER;
  IntValue := aValue;
end;

procedure TLexResult.SetString(aValue: string);
begin
  FIsDouble := false;
  FIsUndefined := false;
  FIsInteger := false;
  Token := tkString;
  StringValue := aValue;
end;

{ TLexState }

procedure TLexState.Advance;
begin
  inc (FcharIndex);
end;

function TLexState.currentChar: char;
begin
  Result := FFormula[FCharIndex];
end;

function TLexState.formula: string;
begin
  Result := FFormula;
end;

procedure TLexState.GoBack;
begin
  dec(FCharIndex);
end;

function TLexState.IsEof: boolean;
begin
  Result := (FcharIndex > FlenFormula);
end;

procedure TLexState.SetFormula(aFormula: string);
begin
  FFormula := aFormula;
  FlenFormula := Length(FFormula);
  FcharIndex := 1;
end;

end.