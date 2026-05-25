(* ============================================================
   MAIN PROGRAM — Ammonia Suction Servo Control
   pCO5+ Large | pCOSystem IDE | IEC 61131-3 Structured Text
   Scan cycle: 500 ms "**IMPORTANT Testing**"
   ============================================================ *)

PROGRAM MainControl

  (* ---------------------------------------------------------- *)
  (* STEP 1: Read & scale pressure sensor                       *)
  (*   AI1 range: 4-20mA mapped to 0.0-100.0 raw units by pCO  *)
  (*   Sensor range: -1.6 bar to +0.0 bar (typical NH3 suction) *)
  (* ---------------------------------------------------------- *)
  rPressureBar := (rPressureRaw / 100.0) * 1.6 - 1.6;
  (* Result: -1.6 bar (raw=0) to 0.0 bar (raw=100) *)

  (* ---------------------------------------------------------- *)
  (* STEP 2: Safety interlock evaluation                        *)
  (*   bEstopHW and bNH3AlarmHW are NORMALLY CLOSED contacts.   *)
  (*   A TRUE signal here means the contact OPENED = danger.    *)
  (* ---------------------------------------------------------- *)
  IF bEstopHW OR bNH3AlarmHW OR bServoDriveFault THEN
    eCtrlMode    := 2;       (* Force SAFE_STOP mode *)
    bAlarmActive := TRUE;
    bAlarmLatched := TRUE;
    IF bEstopHW THEN
      sAlarmMsg := 'E-STOP ACTIVATED';
    ELSIF bNH3AlarmHW THEN
      sAlarmMsg := 'NH3 GAS ALARM - EVACUATE';
    ELSIF bServoDriveFault THEN
      sAlarmMsg := 'SERVO DRIVE FAULT';
    END_IF;
  END_IF;

  (* ---------------------------------------------------------- *)
  (* STEP 3: Alarm reset (only allowed in MANUAL mode)          *)
  (* ---------------------------------------------------------- *)
  IF bHMI_Reset AND (eCtrlMode = 1) THEN
    IF NOT bEstopHW AND NOT bNH3AlarmHW AND NOT bServoDriveFault THEN
      bAlarmLatched := FALSE;
      bAlarmActive  := FALSE;
      sAlarmMsg     := '';
    END_IF;
  END_IF;

  (* ---------------------------------------------------------- *)
  (* STEP 4: Mode switching (only when no latched alarm)        *)
  (* ---------------------------------------------------------- *)
  IF NOT bAlarmLatched THEN
    IF bHMI_AutoReq OR (NOT bManualSel) THEN
      eCtrlMode := 0;   (* AUTO *)
    ELSIF bHMI_ManualReq OR bManualSel THEN
      eCtrlMode := 1;   (* MANUAL *)
    END_IF;
  END_IF;

  (* ---------------------------------------------------------- *)
  (* STEP 5: Execute selected control mode                      *)
  (* ---------------------------------------------------------- *)
  CASE eCtrlMode OF

    0: (* ---- AUTO MODE: PID pressure control --------------- *)
       FC_PID_Control();
       rServoPosCmd := rPID_Output;
       bServoEnabled := TRUE;

    1: (* ---- MANUAL MODE: wireless HMI setpoint ------------ *)
       rServoPosCmd := LIMIT(rPID_OutMin, rManualPosCmdHMI, rPID_OutMax);
       bServoEnabled := TRUE;
       (* Reset PID integrator to prevent wind-up on mode return *)
       rPID_Integral  := rServoPosCmd;
       rPID_PrevError := rPressureBar - rPressureSP;

    2: (* ---- SAFE STOP: close valve, disable drive --------- *)
       rServoPosCmd  := rPID_OutMin;   (* Drive to minimum/closed *)
       bServoEnabled := FALSE;

  END_CASE;

  (* ---------------------------------------------------------- *)
  (* STEP 6: Write command to servo drive via pLAN              *)
  (* ---------------------------------------------------------- *)
  FC_WritePLAN_Servo();

END_PROGRAM
