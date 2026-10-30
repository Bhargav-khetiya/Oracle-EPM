/*===========================================================
  MANPOWER -> Finplan (via Location Alias: _RevCube_)

  Pushes compensation accounts from Manpower cube to
  Finplan cube, mapping each source account to its
  corresponding target account code.

  Account Mapping (Source -> Target):
  ─────────────────────────────────────
  Basic_Salary          -> 200611
  Housing_Allowance     -> 200612
  Conveyance_Allowance  -> 200613
  Medical_Allowance     -> 200614
  Education_Allowance   -> 200615
  Bonus                 -> 200616
  Provident_Fund        -> 200617
  Professional_Tax      -> 200618
  Travelling_Allowance  -> 200619
  Airfare               -> 200620
  Gratuity              -> 200621

  Target-Only Dimension Overrides:
  ─────────────────────────────────
  Future      -> "No Future"
  HSP_View    -> "BaseData"
  PlanElement -> "Calculated"
===========================================================*/


FIX(
    "Budget",                       /* Scenario          */
    "Working",                      /* Version           */
    "E10002",                       /* Entity            */
    &nextyear,                      /* Year (subst var)  */
    @RELATIVE("Period", 0),         /* All level-0 periods */
    @RELATIVE("Currency", 0),       /* All level-0 currencies */
    "Total Employees",              /* Employee dim (aggregated) */
    "Total Grades"                  /* Grade dim (aggregated)    */
)

    /*-------------------------------------------------------
      Each member block provides the calculation context
      for @XWRITE (required — @XWRITE is a top-down formula
      and must be inside a "member"( ... ) block).

      The mbrList maps the source account to the target
      account code, and sets target-only dimensions:
      Future, HSP_View, PlanElement.
    -------------------------------------------------------*/

    "Basic_Salary"(
        @XWRITE("Basic_Salary", _RevCube_, "200611", "No Future", "BaseData", "Calculated");
    )

    "Housing_Allowance"(
        @XWRITE("Housing_Allowance", _RevCube_, "200612", "No Future", "BaseData", "Calculated");
    )

    "Conveyance_Allowance"(
        @XWRITE("Conveyance_Allowance", _RevCube_, "200613", "No Future", "BaseData", "Calculated");
    )

    "Medical_Allowance"(
        @XWRITE("Medical_Allowance", _RevCube_, "200614", "No Future", "BaseData", "Calculated");
    )

    "Education_Allowance"(
        @XWRITE("Education_Allowance", _RevCube_, "200615", "No Future", "BaseData", "Calculated");
    )

    "Bonus"(
        @XWRITE("Bonus", _RevCube_, "200616", "No Future", "BaseData", "Calculated");
    )

    "Provident_Fund"(
        @XWRITE("Provident_Fund", _RevCube_, "200617", "No Future", "BaseData", "Calculated");
    )

    "Professional_Tax"(
        @XWRITE("Professional_Tax", _RevCube_, "200618", "No Future", "BaseData", "Calculated");
    )

    "Travelling_Allowance"(
        @XWRITE("Travelling_Allowance", _RevCube_, "200619", "No Future", "BaseData", "Calculated");
    )

    "Airfare"(
        @XWRITE("Airfare", _RevCube_, "200620", "No Future", "BaseData", "Calculated");
    )

    "Gratuity"(
        @XWRITE("Gratuity", _RevCube_, "200621", "No Future", "BaseData", "Calculated");
    )

ENDFIX
