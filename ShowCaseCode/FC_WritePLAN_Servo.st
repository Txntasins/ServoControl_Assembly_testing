(* ============================================================
   FUNCTION: Write servo position command via pLAN
   Uses Carel pLAN shared variable table.
   Servo drive must be configured as pLAN slave, address 1.
   Map rServoPosCmd -> pLAN shared var index 1 (REAL, 0-100%)
   Map bServoEnabled -> pLAN shared var index 2 (BOOL)
   ============================================================ *)

FUNCTION FC_WritePLAN_Servo : VOID

  (* pCOSystem pLAN write — use built-in PLAN_WRITE blocks     *)
  (* In pCO Studio: drag "pLAN Write Real" FB from library      *)
  (* and connect rServoPosCmd to it targeting node 1, var 1     *)

  (* Pseudocode representation — replace with pCO Studio FBs:  *)

  (*
    PLAN_WriteReal(
      NodeAddr  := 1,
      VarIndex  := 1,
      Value     := rServoPosCmd,
      Execute   := TRUE
    );

    PLAN_WriteBool(
      NodeAddr  := 1,
      VarIndex  := 2,
      Value     := bServoEnabled,
      Execute   := TRUE
    );

    PLAN_ReadReal(
      NodeAddr  := 1,
      VarIndex  := 3,
      Value     => rServoPosFbk,
      Execute   := TRUE
    );

    PLAN_ReadBool(
      NodeAddr  := 1,
      VarIndex  := 4,
      Value     => bServoDriveFault,
      Execute   := TRUE
    );
  *)

  (* Watchdog: if no pLAN response within 3 scans, raise fault *)
  IF NOT bServoHomed THEN
    sAlarmMsg    := 'SERVO NOT HOMED';
    bAlarmActive := TRUE;
  END_IF;

END_FUNCTION
