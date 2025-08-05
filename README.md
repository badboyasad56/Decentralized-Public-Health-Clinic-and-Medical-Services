# Decentralized Public Health Clinic and Medical Services

A comprehensive blockchain-based system for managing public health services, built on the Stacks blockchain using Clarity smart contracts.

## Overview

This system provides a decentralized platform for managing various aspects of public health services, ensuring transparency, accessibility, and efficient coordination of healthcare resources for underserved communities.

## System Components

### 1. Community Health Center Scheduling (`clinic-scheduling.clar`)
- Manages appointment scheduling for public health clinics
- Tracks available time slots and provider schedules
- Handles appointment confirmations and cancellations
- Maintains patient appointment history

### 2. Prescription Assistance Program (`prescription-assistance.clar`)
- Helps low-income patients access affordable medications
- Manages eligibility verification and application processing
- Tracks medication requests and approvals
- Coordinates with pharmacy partners

### 3. Health Screening Program Coordination (`health-screening.clar`)
- Organizes blood pressure, diabetes, and cancer screenings
- Schedules screening events and manages capacity
- Tracks screening results and follow-up requirements
- Generates health reports and statistics

### 4. Mental Health Services Referral (`mental-health-referral.clar`)
- Connects patients with counseling and psychiatric services
- Manages referral requests and provider matching
- Tracks appointment scheduling and outcomes
- Maintains confidential patient records

### 5. Public Health Education (`health-education.clar`)
- Coordinates wellness workshops and disease prevention programs
- Manages event scheduling and participant registration
- Tracks educational program effectiveness
- Distributes health information and resources

## Key Features

- **Decentralized**: No single point of failure or control
- **Transparent**: All transactions and data are recorded on-chain
- **Accessible**: Open to all community members regardless of insurance status
- **Privacy-Focused**: Patient data is protected while maintaining system transparency
- **Cost-Effective**: Reduces administrative overhead through automation

## Data Structures

### Common Data Types
- `patient-id`: Unique identifier for patients (uint)
- `provider-id`: Unique identifier for healthcare providers (uint)
- `appointment-id`: Unique identifier for appointments (uint)
- `program-id`: Unique identifier for programs/services (uint)

### Status Types
- Appointments: pending, confirmed, completed, cancelled
- Applications: submitted, under-review, approved, denied
- Screenings: scheduled, completed, results-pending, follow-up-required

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Caller not authorized for this action
- `ERR-INVALID-INPUT (u101)`: Invalid input parameters
- `ERR-NOT-FOUND (u102)`: Requested resource not found
- `ERR-ALREADY-EXISTS (u103)`: Resource already exists
- `ERR-CAPACITY-FULL (u104)`: No available capacity
- `ERR-INVALID-STATUS (u105)`: Invalid status transition
- `ERR-EXPIRED (u106)`: Request or appointment has expired

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Usage

Each contract can be deployed independently and provides public functions for:
- Creating and managing appointments/applications
- Querying available services and schedules
- Updating status and tracking progress
- Generating reports and statistics

## Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Edge case and error condition testing

Run tests with: `npm test`

## Security Considerations

- All patient data is handled with privacy in mind
- Access controls prevent unauthorized modifications
- Input validation prevents malicious data entry
- Audit trails maintain accountability

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or support, please open an issue in the repository or contact the development team.
