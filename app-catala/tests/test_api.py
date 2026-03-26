"""Tests for the rules engine API."""

from fastapi.testclient import TestClient

from src.api import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_sufficient_balance_medical_leave():
    response = client.post(
        "/evaluate/leave-balance",
        json={
            "leave_type": "medical_leave",
            "leave_periods": [{"length_in_weeks": 4}],
            "leave_taken_in_benefit_year": 0,
            "total_leave_taken_all_types": 0,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["max_entitlement"] == 20
    assert data["leave_balance"] == 20
    assert data["total_requested"] == 4
    assert data["has_sufficient_leave_balance"] is True


def test_sufficient_balance_with_prior_leave():
    response = client.post(
        "/evaluate/leave-balance",
        json={
            "leave_type": "medical_leave",
            "leave_periods": [{"length_in_weeks": 5}],
            "leave_taken_in_benefit_year": 10,
            "total_leave_taken_all_types": 10,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["max_entitlement"] == 20
    assert data["leave_balance"] == 10
    assert data["total_requested"] == 5
    assert data["has_sufficient_leave_balance"] is True


def test_insufficient_balance_exceeds_type_limit():
    response = client.post(
        "/evaluate/leave-balance",
        json={
            "leave_type": "bonding_leave",
            "leave_periods": [{"length_in_weeks": 10}],
            "leave_taken_in_benefit_year": 5,
            "total_leave_taken_all_types": 5,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["max_entitlement"] == 12
    assert data["leave_balance"] == 7
    assert data["total_requested"] == 10
    assert data["has_sufficient_leave_balance"] is False


def test_insufficient_balance_exceeds_overall_cap():
    """Even if type balance is sufficient, overall 26-week cap is exceeded."""
    response = client.post(
        "/evaluate/leave-balance",
        json={
            "leave_type": "care_for_family_service_member",
            "leave_periods": [{"length_in_weeks": 6}],
            "leave_taken_in_benefit_year": 0,
            "total_leave_taken_all_types": 22,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["max_entitlement"] == 26
    assert data["leave_balance"] == 26
    assert data["total_requested"] == 6
    assert data["has_sufficient_leave_balance"] is False


def test_multiple_leave_periods():
    response = client.post(
        "/evaluate/leave-balance",
        json={
            "leave_type": "care_for_family",
            "leave_periods": [
                {"length_in_weeks": 3},
                {"length_in_weeks": 4},
            ],
            "leave_taken_in_benefit_year": 0,
            "total_leave_taken_all_types": 0,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["max_entitlement"] == 12
    assert data["leave_balance"] == 12
    assert data["total_requested"] == 7
    assert data["has_sufficient_leave_balance"] is True


def test_invalid_leave_type():
    response = client.post(
        "/evaluate/leave-balance",
        json={
            "leave_type": "invalid_type",
            "leave_periods": [{"length_in_weeks": 1}],
            "leave_taken_in_benefit_year": 0,
            "total_leave_taken_all_types": 0,
        },
    )
    assert response.status_code == 400
