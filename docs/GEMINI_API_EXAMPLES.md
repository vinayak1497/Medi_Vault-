# Gemini Prescription Extraction - API Examples & Response Formats

## Real-World API Response Examples

### Example 1: Successful Prescription Extraction

#### Request
```json
{
  "contents": [
    {
      "parts": [
        {
          "text": "You are a medical data extraction specialist..."
        },
        {
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": "iVBORw0KGgoAAAANS..."
          }
        }
      ]
    }
  ]
}
```

#### Gemini Response (Success)
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "{\n  \"date_of_consultation\": \"20/06/2023\",\n  \"patient_full_name\": \"John Doe\",\n  \"age\": \"45\",\n  \"sex\": \"Male\",\n  \"address\": \"123 Main Street, City\",\n  \"weight\": \"75\",\n  \"symptoms_seen_now\": \"Radicular symptoms, nerve pain, tingling in legs\",\n  \"opd_or_uhid_number\": \"2023/078/9007784\",\n  \"prescription_details\": [\n    {\n      \"generic_name\": \"Pregabalin\",\n      \"strength_or_potency\": \"100 mg\",\n      \"dosage_form\": \"Tablet\",\n      \"dose\": \"1 tablet\",\n      \"frequency_and_timing\": \"Once daily at night\",\n      \"duration\": \"30 days\",\n      \"quantity_dispensed\": \"30 tablets\",\n      \"directions_and_instructions\": \"Take at bedtime. Do not drive after taking.\"\n    },\n    {\n      \"generic_name\": \"Vitamin B Complex\",\n      \"strength_or_potency\": \"As per formulation\",\n      \"dosage_form\": \"Capsule\",\n      \"dose\": \"1 capsule\",\n      \"frequency_and_timing\": \"Twice daily\",\n      \"duration\": \"30 days\",\n      \"quantity_dispensed\": \"60 capsules\",\n      \"directions_and_instructions\": \"Take with food\"\n    }\n  ],\n  \"special_instructions\": \"Continue existing medications. Avoid alcohol. Regular follow-up needed.\",\n  \"investigations_advised\": \"NCV & UL + LL, Blood glucose test, Vitamin B12 level\",\n  \"dietary_or_lifestyle_advice\": \"Maintain healthy diet. Regular exercise. Avoid prolonged sitting.\"\n}"
          }
        ]
      }
    }
  ]
}
```

#### Parsed Output (Health Buddy)
```dart
Prescription(
  doctorId: 'doc_123',
  createdAt: DateTime.now(),
  prescriptionDate: DateTime(2023, 6, 20),
  
  // Patient Information
  patientName: 'John Doe',
  patientAge: 45,
  patientGender: 'Male',
  patientAddress: '123 Main Street, City',
  patientWeight: '75',
  opdRegistrationNumber: '2023/078/9007784',
  
  // Medical Information
  currentSymptoms: 'Radicular symptoms, nerve pain, tingling in legs',
  
  // Medications
  medications: [
    MedicationItem(
      name: 'Pregabalin',
      genericName: 'Pregabalin',
      strength: '100 mg',
      dosageForm: DosageForm.tablet,
      frequency: DosageFrequency.atBedtime,
      duration: '30 days',
      instructions: 'Take at bedtime. Do not drive after taking.',
    ),
    MedicationItem(
      name: 'Vitamin B Complex',
      genericName: 'Vitamin B Complex',
      strength: 'As per formulation',
      dosageForm: DosageForm.capsule,
      frequency: DosageFrequency.twiceDaily,
      duration: '30 days',
      instructions: 'Take with food',
    ),
  ],
  
  // Instructions
  instructions: 'Continue existing medications. Avoid alcohol. Regular follow-up needed.',
  investigationsAdvised: 'NCV & UL + LL, Blood glucose test, Vitamin B12 level',
  dietaryAdvice: 'Maintain healthy diet. Regular exercise. Avoid prolonged sitting.',
  
  status: PrescriptionStatus.draft,
)
```

---

### Example 2: Incomplete Prescription

#### Gemini Response
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "{\n  \"date_of_consultation\": \"15/10/2024\",\n  \"patient_full_name\": \"Jane Smith\",\n  \"age\": \"32\",\n  \"sex\": \"Female\",\n  \"address\": \"\",\n  \"weight\": \"\",\n  \"symptoms_seen_now\": \"Headache, fever\",\n  \"opd_or_uhid_number\": \"\",\n  \"prescription_details\": [\n    {\n      \"generic_name\": \"Paracetamol\",\n      \"strength_or_potency\": \"500 mg\",\n      \"dosage_form\": \"Tablet\",\n      \"dose\": \"1-2 tablets\",\n      \"frequency_and_timing\": \"Every 4-6 hours\",\n      \"duration\": \"3 days\",\n      \"quantity_dispensed\": \"12 tablets\",\n      \"directions_and_instructions\": \"As needed for pain/fever\"\n    }\n  ],\n  \"special_instructions\": \"\",\n  \"investigations_advised\": \"\",\n  \"dietary_or_lifestyle_advice\": \"Rest well, stay hydrated\"\n}"
          }
        ]
      }
    }
  ]
}
```

#### Parsed Output (Health Buddy)
```dart
Prescription(
  patientName: 'Jane Smith',
  patientAge: 32,
  patientGender: 'Female',
  patientAddress: '',  // Empty string as field not found
  patientWeight: '',   // Empty string as field not found
  currentSymptoms: 'Headache, fever',
  opdRegistrationNumber: '', // Empty string as field not found
  
  medications: [
    MedicationItem(
      name: 'Paracetamol',
      strength: '500 mg',
      dosageForm: DosageForm.tablet,
      frequency: DosageFrequency.every4Hours,
      duration: '3 days',
    ),
  ],
  
  dietaryAdvice: 'Rest well, stay hydrated',
  // Other fields remain null/empty
)
```

---

### Example 3: Handwritten Prescription (Complex)

#### Gemini Response
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "{\n  \"date_of_consultation\": \"25/09/2024\",\n  \"patient_full_name\": \"Raj Kumar Sharma\",\n  \"age\": \"58\",\n  \"sex\": \"Male\",\n  \"address\": \"456 Oak Avenue, Metro City\",\n  \"weight\": \"82\",\n  \"symptoms_seen_now\": \"Chest pain, shortness of breath, palpitations\",\n  \"opd_or_uhid_number\": \"HC/2024/5847\",\n  \"prescription_details\": [\n    {\n      \"generic_name\": \"Atorvastatin\",\n      \"strength_or_potency\": \"20 mg\",\n      \"dosage_form\": \"Tablet\",\n      \"dose\": \"1 tablet\",\n      \"frequency_and_timing\": \"Once daily at night\",\n      \"duration\": \"3 months\",\n      \"quantity_dispensed\": \"90 tablets\",\n      \"directions_and_instructions\": \"Take at bedtime with water\"\n    },\n    {\n      \"generic_name\": \"Aspirin\",\n      \"strength_or_potency\": \"75 mg\",\n      \"dosage_form\": \"Tablet\",\n      \"dose\": \"1 tablet\",\n      \"frequency_and_timing\": \"Once daily in morning\",\n      \"duration\": \"Ongoing\",\n      \"quantity_dispensed\": \"30 tablets\",\n      \"directions_and_instructions\": \"Take with food after breakfast\"\n    },\n    {\n      \"generic_name\": \"Metoprolol\",\n      \"strength_or_potency\": \"50 mg\",\n      \"dosage_form\": \"Tablet\",\n      \"dose\": \"1 tablet\",\n      \"frequency_and_timing\": \"Twice daily\",\n      \"duration\": \"3 months\",\n      \"quantity_dispensed\": \"180 tablets\",\n      \"directions_and_instructions\": \"Measure pulse before taking\"\n    }\n  ],\n  \"special_instructions\": \"Strict no salt diet. Monitor blood pressure daily. Avoid stressful situations.\",\n  \"investigations_advised\": \"ECG, Lipid profile, Troponin levels, Stress test\",\n  \"dietary_or_lifestyle_advice\": \"Low fat, low salt diet. 30 mins walk daily. Quit smoking if applicable.\"\n}"
          }
        ]
      }
    }
  ]
}
```

#### Parsed Output (Health Buddy)
```dart
Prescription(
  patientName: 'Raj Kumar Sharma',
  patientAge: 58,
  patientGender: 'Male',
  patientAddress: '456 Oak Avenue, Metro City',
  patientWeight: '82',
  opdRegistrationNumber: 'HC/2024/5847',
  
  currentSymptoms: 'Chest pain, shortness of breath, palpitations',
  
  medications: [
    MedicationItem(
      name: 'Atorvastatin',
      strength: '20 mg',
      dosageForm: DosageForm.tablet,
      frequency: DosageFrequency.atBedtime,
      duration: '3 months',
    ),
    MedicationItem(
      name: 'Aspirin',
      strength: '75 mg',
      dosageForm: DosageForm.tablet,
      frequency: DosageFrequency.onceDaily,
      duration: 'Ongoing',
    ),
    MedicationItem(
      name: 'Metoprolol',
      strength: '50 mg',
      dosageForm: DosageForm.tablet,
      frequency: DosageFrequency.twiceDaily,
      duration: '3 months',
    ),
  ],
  
  instructions: 'Strict no salt diet. Monitor blood pressure daily. Avoid stressful situations.',
  investigationsAdvised: 'ECG, Lipid profile, Troponin levels, Stress test',
  dietaryAdvice: 'Low fat, low salt diet. 30 mins walk daily. Quit smoking if applicable.',
)
```

---

## Error Response Examples

### Error 1: Invalid API Key

```json
{
  "error": {
    "code": 401,
    "message": "The API key provided is invalid or has expired.",
    "status": "UNAUTHENTICATED"
  }
}
```

**Health Buddy Handling:**
```dart
{
  'error': 'API key authentication failed. Please check your Gemini API key.',
  'data': null
}
```

---

### Error 2: Rate Limit Exceeded

```json
{
  "error": {
    "code": 429,
    "message": "Resource has been exhausted (e.g. check quota).",
    "status": "RESOURCE_EXHAUSTED"
  }
}
```

**Health Buddy Handling:**
```dart
{
  'error': 'API rate limit exceeded. Please wait and try again.',
  'data': null
}
```

---

### Error 3: Invalid Image Format

```json
{
  "error": {
    "code": 400,
    "message": "Request contains an invalid argument.",
    "status": "INVALID_ARGUMENT"
  }
}
```

**Health Buddy Handling:**
```dart
{
  'error': 'Error extracting prescription: Invalid image format',
  'data': null
}
```

---

### Error 4: Request Timeout

```dart
{
  'error': 'Request timeout. Please check your internet connection.',
  'data': null
}
```

---

## Frequency & Dosage Form Abbreviation Guide

### Frequency Abbreviations Supported

| Abbreviation | Full Form | Enum Value |
|---|---|---|
| OD | Once Daily | `onceDaily` |
| BD | Twice Daily | `twiceDaily` |
| TDS | Three Times Daily | `threeTimes` |
| QID | Four Times Daily | `fourTimes` |
| Every 4H | Every 4 Hours | `every4Hours` |
| Every 6H | Every 6 Hours | `every6Hours` |
| Every 8H | Every 8 Hours | `every8Hours` |
| Every 12H | Every 12 Hours | `every12Hours` |
| PRN | As Needed | `asNeeded` |
| AC | Before Meals | `beforeMeals` |
| PC | After Meals | `afterMeals` |
| HS | At Bedtime | `atBedtime` |
| Empty Stomach | On Empty Stomach | `onEmptyStomach` |

### Dosage Form Abbreviations

| Form | Enum Value |
|---|---|
| Tablet, Tab, T | `tablet` |
| Capsule, Cap, C | `capsule` |
| Syrup, Solution, Liquid | `syrup` |
| Injection, IV, IM, SC | `injection` |
| Cream, Ointment, Oil | `cream` |
| Powder, Dust | `powder` |

---

## Date Format Variations Handled

The service automatically parses dates in these formats:

```
DD/MM/YYYY     → 20/06/2023
DD-MM-YYYY     → 20-06-2023
MM/DD/YYYY     → 06/20/2023
DD.MM.YYYY     → 20.06.2023
YYYY-MM-DD     → 2023-06-20
```

If parsing fails, it defaults to `DateTime.now()`.

---

## Field Mapping Reference

### Complete Gemini → Prescription Mapping

```
Gemini Field                    → Prescription Field
────────────────────────────────────────────────────
date_of_consultation            → prescriptionDate
patient_full_name               → patientName
age                             → patientAge (int)
sex                             → patientGender
address                         → patientAddress
weight                          → patientWeight (string)
symptoms_seen_now               → currentSymptoms
opd_or_uhid_number              → opdRegistrationNumber

Medication Details Array:
generic_name                    → MedicationItem.name
strength_or_potency             → MedicationItem.strength
dosage_form                     → MedicationItem.dosageForm (enum)
frequency_and_timing            → MedicationItem.frequency (enum)
duration                        → MedicationItem.duration
directions_and_instructions     → MedicationItem.instructions

special_instructions            → instructions
investigations_advised          → investigationsAdvised
dietary_or_lifestyle_advice     → dietaryAdvice
```

---

## Test Data for Development

### Sample Prescription 1 (Simple)
```json
{
  "date_of_consultation": "15/10/2024",
  "patient_full_name": "Test Patient 1",
  "age": "30",
  "sex": "Male",
  "address": "",
  "weight": "",
  "symptoms_seen_now": "Common cold, cough",
  "opd_or_uhid_number": "",
  "prescription_details": [
    {
      "generic_name": "Paracetamol",
      "strength_or_potency": "500 mg",
      "dosage_form": "Tablet",
      "dose": "1 tablet",
      "frequency_and_timing": "Three times daily",
      "duration": "5 days",
      "quantity_dispensed": "15 tablets",
      "directions_and_instructions": "After meals"
    }
  ],
  "special_instructions": "",
  "investigations_advised": "",
  "dietary_or_lifestyle_advice": "Rest and drink plenty of fluids"
}
```

### Sample Prescription 2 (Complex)
```json
{
  "date_of_consultation": "25/09/2024",
  "patient_full_name": "Test Patient 2",
  "age": "55",
  "sex": "Female",
  "address": "Test City",
  "weight": "65",
  "symptoms_seen_now": "Diabetes, hypertension",
  "opd_or_uhid_number": "TEST/2024/12345",
  "prescription_details": [
    {
      "generic_name": "Metformin",
      "strength_or_potency": "500 mg",
      "dosage_form": "Tablet",
      "dose": "1 tablet",
      "frequency_and_timing": "Twice daily",
      "duration": "3 months",
      "quantity_dispensed": "180 tablets",
      "directions_and_instructions": "After meals"
    },
    {
      "generic_name": "Amlodipine",
      "strength_or_potency": "5 mg",
      "dosage_form": "Tablet",
      "dose": "1 tablet",
      "frequency_and_timing": "Once daily",
      "duration": "3 months",
      "quantity_dispensed": "90 tablets",
      "directions_and_instructions": "Morning with water"
    }
  ],
  "special_instructions": "Monitor blood sugar and BP regularly",
  "investigations_advised": "Blood glucose, BP, Lipid profile",
  "dietary_or_lifestyle_advice": "Low carb, low salt diet. Regular exercise."
}
```

---

**For more information, see the main GEMINI_PRESCRIPTION_EXTRACTION.md documentation.**
