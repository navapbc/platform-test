"""FastAPI wrapper for Catala-generated rules engine."""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from src.generated.Paidleave import (
    LeaveBalanceIn,
    LeaveType,
    LeaveType_Code,
    LeavePeriod,
    leave_balance,
)
from src.generated.catala_runtime import Integer


app = FastAPI(
    title="Rules Engine API",
    description="API for evaluating rules compiled from Catala legislative specifications.",
)


class LeavePeriodInput(BaseModel):
    length_in_weeks: int


class LeaveBalanceInput(BaseModel):
    leave_type: str
    leave_periods: list[LeavePeriodInput]
    leave_taken_in_benefit_year: int
    total_leave_taken_all_types: int


class LeaveBalanceResult(BaseModel):
    max_entitlement: int
    leave_balance: int
    total_requested: int
    has_sufficient_leave_balance: bool


LEAVE_TYPE_MAP = {
    "medical_leave": LeaveType_Code.MedicalLeave,
    "bonding_leave": LeaveType_Code.BondingLeave,
    "care_for_family": LeaveType_Code.CareForFamily,
    "care_for_family_service_member": LeaveType_Code.CareForFamilyServiceMember,
}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.post("/evaluate/leave-balance", response_model=LeaveBalanceResult)
def evaluate_leave_balance(input: LeaveBalanceInput) -> LeaveBalanceResult:
    """Evaluate leave balance sufficiency using Catala-compiled rules."""
    leave_type_code = LEAVE_TYPE_MAP.get(input.leave_type)
    if leave_type_code is None:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid leave_type '{input.leave_type}'. "
            f"Must be one of: {', '.join(LEAVE_TYPE_MAP.keys())}",
        )

    try:
        catala_leave_type = LeaveType(code=leave_type_code, value=None)
        catala_periods = [
            LeavePeriod(length_in_weeks=Integer(p.length_in_weeks)) for p in input.leave_periods
        ]

        scope_result = leave_balance(
            LeaveBalanceIn(
                application_leave_type_in=catala_leave_type,
                leave_periods_in=catala_periods,
                leave_taken_in_benefit_year_in=Integer(input.leave_taken_in_benefit_year),
                total_leave_taken_all_types_in=Integer(input.total_leave_taken_all_types),
            )
        )

        return LeaveBalanceResult(
            max_entitlement=int(scope_result.max_entitlement.value),
            leave_balance=int(scope_result.leave_balance.value),
            total_requested=int(scope_result.total_requested.value),
            has_sufficient_leave_balance=scope_result.has_sufficient_leave_balance,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e
