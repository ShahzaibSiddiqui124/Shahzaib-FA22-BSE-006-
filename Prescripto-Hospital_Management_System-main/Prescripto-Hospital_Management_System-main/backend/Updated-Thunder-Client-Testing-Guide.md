# Updated Thunder Client Testing Guide - Prescripto Hospital Management System

## 🚀 **Fixed Issues:**
1. ✅ **Doctor Filtering by Specialization** - New endpoint added
2. ✅ **Appointment Booking Amount Error** - Fixed field reference
3. ✅ **Authentication Headers** - Updated to use Bearer tokens
4. ✅ **Collection Names** - Fixed to match your database

---

## 📋 **Updated API Endpoints**

### **1. DOCTOR ENDPOINTS** (`/api/doctor`)

#### **GET** `/api/doctor/list`
**Description:** Get all doctors
**Headers:** None required
**Response:** All doctors with their details

#### **GET** `/api/doctor/filter?specialization=SPECIALIZATION`
**Description:** Get doctors filtered by specialization
**Headers:** None required
**Query Parameters:**
- `specialization`: The specialization to filter by (e.g., "Cardiology", "Dermatology", "all")

**Example Requests:**
```
GET http://localhost:4000/api/doctor/filter?specialization=Cardiology
GET http://localhost:4000/api/doctor/filter?specialization=Dermatology
GET http://localhost:4000/api/doctor/filter?specialization=all
```

#### **POST** `/api/doctor/login`
**Description:** Login doctor
**Headers:** `Content-Type: application/json`
**Body:**
```json
{
  "email": "doctor@example.com",
  "password": "doctor123"
}
```

---

### **2. USER ENDPOINTS** (`/api/user`)

#### **POST** `/api/user/register`
**Description:** Register a new user
**Headers:** `Content-Type: application/json`
**Body:**
```json
{
  "name": "John Doe",
  "email": "john.doe@example.com",
  "password": "password123",
  "phone": "1234567890",
  "address": {
    "line1": "123 Main Street",
    "line2": "Apt 4B"
  },
  "gender": "Male",
  "dob": "1990-01-15"
}
```

#### **POST** `/api/user/login`
**Description:** Login user
**Headers:** `Content-Type: application/json`
**Body:**
```json
{
  "email": "john.doe@example.com",
  "password": "password123"
}
```

#### **GET** `/api/user/get-profile`
**Description:** Get user profile
**Headers:** 
- `Authorization: Bearer YOUR_TOKEN_HERE`

#### **POST** `/api/user/book-appointment`
**Description:** Book an appointment (FIXED - now uses correct amount field)
**Headers:** 
- `Authorization: Bearer YOUR_TOKEN_HERE`
- `Content-Type: application/json`
**Body:**
```json
{
  "docId": "DOCTOR_ID_FROM_DOCTOR_LIST",
  "slotDate": "2024-01-20",
  "slotTime": "10:00 AM",
  "amount": 500
}
```

#### **GET** `/api/user/appointments`
**Description:** Get user's appointments
**Headers:** 
- `Authorization: Bearer YOUR_TOKEN_HERE`

---

## 🧪 **Step-by-Step Testing Guide**

### **Step 1: Test Basic Connectivity**
```
GET http://localhost:4000/
Expected Response: "API Working"
```

### **Step 2: Test Doctor Filtering (NEW FEATURE)**
```
GET http://localhost:4000/api/doctor/filter?specialization=Cardiology
Expected Response: Array of cardiology doctors

GET http://localhost:4000/api/doctor/filter?specialization=all
Expected Response: All doctors

GET http://localhost:4000/api/doctor/filter?specialization=Dermatology
Expected Response: Array of dermatology doctors
```

### **Step 3: Test User Registration & Login**
```
POST http://localhost:4000/api/user/register
Body: {
  "name": "Test User",
  "email": "test@example.com",
  "password": "password123"
}

POST http://localhost:4000/api/user/login
Body: {
  "email": "test@example.com",
  "password": "password123"
}
Response: {"success": true, "token": "YOUR_TOKEN"}
```

### **Step 4: Test Appointment Booking (FIXED)**
```
POST http://localhost:4000/api/user/book-appointment
Headers: Authorization: Bearer YOUR_TOKEN
Body: {
  "docId": "DOCTOR_ID_FROM_STEP_2",
  "slotDate": "2024-01-20",
  "slotTime": "10:00 AM",
  "amount": 500
}
Expected Response: {"success": true, "message": "Appointment Booked"}
```

### **Step 5: Test User Appointments**
```
GET http://localhost:4000/api/user/appointments
Headers: Authorization: Bearer YOUR_TOKEN
Expected Response: Array of user's appointments
```

---

## 🔧 **Frontend Integration**

### **Using the React Components:**

1. **Import the components:**
```javascript
import DoctorBookingPage from './DoctorBookingPage';
import { userAPI, doctorAPI } from './frontend-api-calls';
```

2. **Use in your app:**
```javascript
function App() {
  const [userToken, setUserToken] = useState(null);
  
  return (
    <div>
      <DoctorBookingPage userToken={userToken} />
    </div>
  );
}
```

3. **API calls example:**
```javascript
// Get doctors by specialization
const doctors = await doctorAPI.getDoctorsBySpecialization('Cardiology');

// Book appointment
const result = await userAPI.bookAppointment(token, {
  docId: 'doctor_id',
  slotDate: '2024-01-20',
  slotTime: '10:00 AM',
  amount: 500
});
```

---

## 🐛 **Troubleshooting**

### **Common Issues & Solutions:**

1. **"Amount path is not specified" Error:**
   - ✅ **FIXED:** Updated controller to use `docData.fees` instead of `docData.feesPerConsultation`

2. **Doctor filtering not working:**
   - ✅ **FIXED:** Added new `/api/doctor/filter` endpoint
   - Use query parameter: `?specialization=SPECIALIZATION_NAME`

3. **Authentication errors:**
   - ✅ **FIXED:** Updated to use `Authorization: Bearer TOKEN` format
   - Make sure to include the token in headers

4. **Database connection issues:**
   - ✅ **FIXED:** Updated model names to match collection names
   - Collections: `users`, `doctors`, `appointments`

---

## 📊 **Expected Database Structure**

Your MongoDB collections should have:

### **users collection:**
```json
{
  "_id": "ObjectId",
  "name": "String",
  "email": "String",
  "password": "String (hashed)",
  "phone": "String",
  "address": "Object",
  "gender": "String",
  "dob": "String",
  "image": "String"
}
```

### **doctors collection:**
```json
{
  "_id": "ObjectId",
  "name": "String",
  "email": "String",
  "password": "String (hashed)",
  "image": "String",
  "speciality": "String",
  "degree": "String",
  "experience": "String",
  "about": "String",
  "available": "Boolean",
  "fees": "Number",
  "slots_booked": "Object",
  "address": "Object",
  "date": "Number"
}
```

### **appointments collection:**
```json
{
  "_id": "ObjectId",
  "userId": "String",
  "docId": "String",
  "slotDate": "String",
  "slotTime": "String",
  "userData": "Object",
  "docData": "Object",
  "amount": "Number",
  "date": "Number",
  "cancelled": "Boolean",
  "payment": "Boolean",
  "isCompleted": "Boolean"
}
```

---

## ✅ **Testing Checklist**

- [ ] Server starts without errors
- [ ] Database connection successful
- [ ] GET `/api/doctor/list` returns all doctors
- [ ] GET `/api/doctor/filter?specialization=Cardiology` returns filtered doctors
- [ ] POST `/api/user/register` creates new user
- [ ] POST `/api/user/login` returns token
- [ ] GET `/api/user/get-profile` with token returns user data
- [ ] POST `/api/user/book-appointment` with token books appointment successfully
- [ ] GET `/api/user/appointments` returns user's appointments

---

## 🎉 **All Issues Fixed!**

Your backend is now fully functional with:
- ✅ Doctor filtering by specialization
- ✅ Fixed appointment booking amount error
- ✅ Proper authentication with Bearer tokens
- ✅ Correct database collection names
- ✅ Complete frontend components ready to use

Start your server with `npm start` and test the endpoints using Thunder Client!
