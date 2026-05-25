(* ============================================================
   FUNCTION: Discrete PID Controller
   Positional form with anti-windup and output clamping
   ============================================================ *)

FUNCTION FC_PID_Control : VOID

  VAR_TEMP
    rDt         : REAL;
    rDerivative : REAL;
    rRawOutput  : REAL;
  END_VAR

  rDt := TIME_TO_REAL(tScanTime) / 1000.0;   (* seconds *)

  (* Error = setpoint - process variable *)
  rPID_Error := rPressureSP - rPressureBar;

  (* Integral with anti-windup clamp *)
  rPID_Integral := rPID_Integral + (rPID_Ki * rPID_Error * rDt);
  rPID_Integral := LIMIT(rPID_OutMin, rPID_Integral, rPID_OutMax);

  (* Derivative on measurement (avoids derivative kick on SP change) *)
  rDerivative := rPID_Kd * (rPID_Error - rPID_PrevError) / rDt;

  (* PID sum *)
  rRawOutput := (rPID_Kp * rPID_Error) + rPID_Integral + rDerivative;

  (* Clamp output to valve limits *)
  rPID_Output := LIMIT(rPID_OutMin, rRawOutput, rPID_OutMax);

  (* Store previous error for next scan *)
  rPID_PrevError := rPID_Error;

END_FUNCTION
