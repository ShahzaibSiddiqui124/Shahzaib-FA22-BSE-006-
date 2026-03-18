// Backend API Test Script
// Run this in your browser console or as a separate test file to verify your backend endpoints

const BACKEND_URL = 'http://localhost:3000'; // Update this to match your backend URL

// Test function to check if backend is running
async function testBackendConnection() {
    try {
        console.log('Testing backend connection...');
        const response = await fetch(`${BACKEND_URL}/api/doctor/list`);
        const data = await response.json();
        console.log('Backend response:', data);
        return data;
    } catch (error) {
        console.error('Backend connection failed:', error);
        return null;
    }
}

// Test function to check doctors endpoint
async function testDoctorsEndpoint() {
    try {
        console.log('Testing doctors endpoint...');
        const response = await fetch(`${BACKEND_URL}/api/doctor/list`);
        const data = await response.json();
        console.log('Doctors data:', data);
        
        if (data.success && data.doctors) {
            console.log(`Found ${data.doctors.length} doctors`);
            console.log('Sample doctor:', data.doctors[0]);
        } else {
            console.error('Doctors endpoint returned error:', data.message);
        }
        return data;
    } catch (error) {
        console.error('Doctors endpoint test failed:', error);
        return null;
    }
}

// Test function to check users endpoint (requires authentication)
async function testUsersEndpoint(token) {
    if (!token) {
        console.log('No token provided, skipping users endpoint test');
        return;
    }
    
    try {
        console.log('Testing users endpoint...');
        const response = await fetch(`${BACKEND_URL}/api/user/get-profile`, {
            headers: {
                'token': token
            }
        });
        const data = await response.json();
        console.log('User profile data:', data);
        return data;
    } catch (error) {
        console.error('Users endpoint test failed:', error);
        return null;
    }
}

// Test function to check appointments endpoint (requires authentication)
async function testAppointmentsEndpoint(token) {
    if (!token) {
        console.log('No token provided, skipping appointments endpoint test');
        return;
    }
    
    try {
        console.log('Testing appointments endpoint...');
        const response = await fetch(`${BACKEND_URL}/api/user/appointments`, {
            headers: {
                'token': token
            }
        });
        const data = await response.json();
        console.log('Appointments data:', data);
        return data;
    } catch (error) {
        console.error('Appointments endpoint test failed:', error);
        return null;
    }
}

// Run all tests
async function runAllTests() {
    console.log('=== Backend API Tests ===');
    
    // Test basic connection
    await testBackendConnection();
    
    // Test doctors endpoint
    await testDoctorsEndpoint();
    
    // Test authenticated endpoints (you'll need to provide a valid token)
    const token = localStorage.getItem('token'); // Get token from localStorage if available
    if (token) {
        await testUsersEndpoint(token);
        await testAppointmentsEndpoint(token);
    } else {
        console.log('No authentication token found. Login first to test authenticated endpoints.');
    }
}

// Export functions for use in browser console
window.testBackend = {
    testBackendConnection,
    testDoctorsEndpoint,
    testUsersEndpoint,
    testAppointmentsEndpoint,
    runAllTests
};

console.log('Backend test functions loaded. Use window.testBackend.runAllTests() to run all tests.');
