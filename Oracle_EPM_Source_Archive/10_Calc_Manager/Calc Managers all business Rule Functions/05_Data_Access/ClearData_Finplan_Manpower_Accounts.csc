/*===========================================================
  CLEAR DATA — Finplan (Target Cube)
  
  Run this ON the Finplan cube BEFORE executing the
  Manpower_to_Finplan_XWRITE script.

  Clears the exact target intersections that @XWRITE
  will write to, ensuring no stale data remains.

  Target Accounts: 200611 - 200621
  (All compensation accounts pushed from Manpower)
===========================================================*/


FIX(
    "Budget",                       /* Scenario          */
    "Working",                      /* Version           */
    "E10002",                       /* Entity            */
    &nextyear,                      /* Year (subst var)  */
    @RELATIVE("Period", 0),         /* All level-0 periods   */
    @RELATIVE("Currency", 0),       /* All level-0 currencies */
    "No Future",                    /* Future dim        */
    "BaseData",                     /* HSP_View dim      */
    "Calculated"                    /* PlanElement dim   */
)

    CLEARDATA
        "200611",   /* Basic_Salary         */
        "200612",   /* Housing_Allowance    */
        "200613",   /* Conveyance_Allowance */
        "200614",   /* Medical_Allowance    */
        "200615",   /* Education_Allowance  */
        "200616",   /* Bonus               */
        "200617",   /* Provident_Fund       */
        "200618",   /* Professional_Tax     */
        "200619",   /* Travelling_Allowance */
        "200620",   /* Airfare             */
        "200621";   /* Gratuity            */

ENDFIX
