unit TestCase1;

{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, Contnrs, mMathUtility

  {$IFNDEF FPC}, IOUtils, TestFramework
  {$ELSE}
  ,fpcunit, testutils, testregistry
  {$ENDIF};

type

  { TTestCase1 }

  TTestCase1= class(TTestCase)
  published
    procedure TestRounding;
    procedure TestGetFractionalPartDigits;
  end;

implementation

procedure TTestCase1.TestRounding;
begin
  CheckEquals(2, RoundToExt(1.5, rmHalfRoundAwayFromZero, 0));
  CheckEquals(-2, RoundToExt(-1.5,rmHalfRoundAwayFromZero, 0));
  CheckEquals(1.7, RoundToExt(1.65, rmHalfRoundAwayFromZero, 1));
  CheckEquals(-1.7, RoundToExt(-1.65,rmHalfRoundAwayFromZero, 1));
  CheckEquals(1.4, RoundToExt(1.36, rmHalfRoundAwayFromZero, 1));
  CheckEquals(1.4, RoundToExt(1.42, rmHalfRoundAwayFromZero, 1));
  CheckEquals(-1.4, RoundToExt(-1.36, rmHalfRoundAwayFromZero, 1));
  CheckEquals(-1.4, RoundToExt(-1.42, rmHalfRoundAwayFromZero, 1));

  CheckEquals(1, RoundToExt(1.5, rmHalfRoundTowardsZero, 0));
  CheckEquals(-1, RoundToExt(-1.5,rmHalfRoundTowardsZero, 0));
  CheckEquals(1.6, RoundToExt(1.65, rmHalfRoundTowardsZero, 1));
  CheckEquals(-1.6, RoundToExt(-1.65,rmHalfRoundTowardsZero, 1));
  CheckEquals(1.4, RoundToExt(1.36, rmHalfRoundTowardsZero, 1));
  CheckEquals(1.4, RoundToExt(1.42, rmHalfRoundTowardsZero, 1));
  CheckEquals(-1.4, RoundToExt(-1.36, rmHalfRoundTowardsZero, 1));
  CheckEquals(-1.4, RoundToExt(-1.42, rmHalfRoundTowardsZero, 1));

  CheckEquals(2, RoundToExt(1.5, rmHalfRoundUp, 0));
  CheckEquals(-1, RoundToExt(-1.5,rmHalfRoundUp, 0));
  CheckEquals(1.7, RoundToExt(1.65, rmHalfRoundUp, 1));
  CheckEquals(-1.6, RoundToExt(-1.65,rmHalfRoundUp, 1));
  CheckEquals(1.4, RoundToExt(1.36, rmHalfRoundUp, 1));
  CheckEquals(1.4, RoundToExt(1.42, rmHalfRoundUp, 1));
  CheckEquals(-1.4, RoundToExt(-1.36, rmHalfRoundUp, 1));
  CheckEquals(-1.4, RoundToExt(-1.42, rmHalfRoundUp, 1));


  CheckEquals(1, RoundToExt(1.5, rmHalfRoundDown, 0));
  CheckEquals(-2, RoundToExt(-1.5,rmHalfRoundDown, 0));
  CheckEquals(1.6, RoundToExt(1.65, rmHalfRoundDown, 1));
  CheckEquals(-1.7, RoundToExt(-1.65,rmHalfRoundDown, 1));
  CheckEquals(1.4, RoundToExt(1.36, rmHalfRoundDown, 1));
  CheckEquals(1.4, RoundToExt(1.42, rmHalfRoundDown, 1));
  CheckEquals(-1.4, RoundToExt(-1.36, rmHalfRoundDown, 1));
  CheckEquals(-1.4, RoundToExt(-1.42, rmHalfRoundDown, 1));

  CheckEquals(2, RoundToExt(1.5, rmHalfRoundToEven, 0));
  CheckEquals(-2, RoundToExt(-1.5,rmHalfRoundToEven, 0));
  CheckEquals(1.6, RoundToExt(1.65, rmHalfRoundToEven, 1));
  CheckEquals(-1.6, RoundToExt(-1.65,rmHalfRoundToEven, 1));
  CheckEquals(1.4, RoundToExt(1.45, rmHalfRoundToEven, 1));
  CheckEquals(-1.4, RoundToExt(-1.45,rmHalfRoundToEven, 1));
  CheckEquals(1.4, RoundToExt(1.36, rmHalfRoundToEven, 1));
  CheckEquals(1.4, RoundToExt(1.42, rmHalfRoundToEven, 1));
  CheckEquals(-1.4, RoundToExt(-1.36, rmHalfRoundToEven, 1));
  CheckEquals(-1.4, RoundToExt(-1.42, rmHalfRoundToEven, 1));

  CheckEquals(1, RoundToExt(1.5, rmHalfRoundToOdd, 0));
  CheckEquals(-1, RoundToExt(-1.5,rmHalfRoundToOdd, 0));
  CheckEquals(1.7, RoundToExt(1.65, rmHalfRoundToOdd, 1));
  CheckEquals(-1.7, RoundToExt(-1.65,rmHalfRoundToOdd, 1));
  CheckEquals(1.5, RoundToExt(1.45, rmHalfRoundToOdd, 1));
  CheckEquals(-1.5, RoundToExt(-1.45,rmHalfRoundToOdd, 1));
  CheckEquals(1.4, RoundToExt(1.36, rmHalfRoundToOdd, 1));
  CheckEquals(1.4, RoundToExt(1.42, rmHalfRoundToOdd, 1));
  CheckEquals(-1.4, RoundToExt(-1.36, rmHalfRoundToOdd, 1));
  CheckEquals(-1.4, RoundToExt(-1.42, rmHalfRoundToOdd, 1));

  CheckEquals(788938.59, RoundToExt(788938.59000154, rmHalfRoundAwayFromZero, 2));

end;

procedure TTestCase1.TestGetFractionalPartDigits;
begin
  CheckEquals(0, GetFractionalPartDigits(5));
  CheckEquals(0, GetFractionalPartDigits(1002));
  CheckEquals(0, GetFractionalPartDigits(-23));
  CheckEquals(1, GetFractionalPartDigits(5.7));
  CheckEquals(1, GetFractionalPartDigits(145.1));
  CheckEquals(1, GetFractionalPartDigits(-9.9));
  CheckEquals(2, GetFractionalPartDigits(8.71));
  CheckEquals(2, GetFractionalPartDigits(8.98));
  CheckEquals(2, GetFractionalPartDigits(5480.01));
  CheckEquals(2, GetFractionalPartDigits(-54.99));
  CheckEquals(3, GetFractionalPartDigits(4.578));
  CheckEquals(3, GetFractionalPartDigits(587.001));
  CheckEquals(3, GetFractionalPartDigits(-99.123));
  CheckEquals(5, GetFractionalPartDigits(58.00001));
  CheckEquals(5, GetFractionalPartDigits(58.99999));
end;



initialization
{$IFDEF FPC}
  RegisterTest(TTestCase1);
{$ELSE}
  RegisterTest(TTestCase1.Suite);
{$ENDIF}
end.

