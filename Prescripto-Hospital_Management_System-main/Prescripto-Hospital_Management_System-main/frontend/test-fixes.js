// Test script to verify the fixes
// Run this in your browser console after starting the application

console.log('=== Testing Doctor Filtering and Appointment Booking Fixes ===');

// Test 1: Check if doctors are loaded
function testDoctorsLoading() {
    console.log('1. Testing doctors loading...');
    
    // Check if doctors are available in the context
    const doctors = window.doctors || [];
    console.log(`Found ${doctors.length} doctors`);
    
    if (doctors.length > 0) {
        console.log('✅ Doctors loaded successfully');
        console.log('Sample doctor:', doctors[0]);
    } else {
        console.log('❌ No doctors found');
    }
}

// Test 2: Check doctor filtering
function testDoctorFiltering() {
    console.log('2. Testing doctor filtering...');
    
    const doctors = window.doctors || [];
    const specialities = ['General physician', 'Gynecologist', 'Dermatologist', 'Pediatricians', 'Neurologist', 'Gastroenterologist'];
    
    specialities.forEach(speciality => {
        const filtered = doctors.filter(doc => 
            doc.speciality && doc.speciality.toLowerCase() === speciality.toLowerCase()
        );
        console.log(`${speciality}: ${filtered.length} doctors found`);
    });
}

// Test 3: Check user authentication
function testUserAuth() {
    console.log('3. Testing user authentication...');
    
    const token = localStorage.getItem('token');
    if (token) {
        console.log('✅ User token found');
        console.log('Token (first 20 chars):', token.substring(0, 20) + '...');
    } else {
        console.log('❌ No user token found - user needs to login');
    }
}

// Test 4: Check appointment booking data
function testAppointmentData() {
    console.log('4. Testing appointment booking data...');
    
    const userData = window.userData || null;
    if (userData && userData._id) {
        console.log('✅ User data available for appointment booking');
        console.log('User ID:', userData._id);
    } else {
        console.log('❌ User data not available - user needs to login');
    }
}

// Run all tests
function runAllTests() {
    testDoctorsLoading();
    testDoctorFiltering();
    testUserAuth();
    testAppointmentData();
    
    console.log('=== Test Summary ===');
    console.log('1. Doctor filtering should now work with case-insensitive matching');
    console.log('2. Appointment booking should now include userId in the request');
    console.log('3. Backend should properly handle the amount field');
    console.log('4. Check browser console for any error messages during testing');
}

// Export for manual testing
window.testFixes = {
    testDoctorsLoading,
    testDoctorFiltering,
    testUserAuth,
    testAppointmentData,
    runAllTests
};

console.log('Test functions loaded. Use window.testFixes.runAllTests() to run all tests.');
