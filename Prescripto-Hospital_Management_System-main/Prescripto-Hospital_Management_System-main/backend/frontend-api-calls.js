// Frontend API calls for Prescripto Hospital Management System
// This file contains all the API calls needed for the frontend

const API_BASE_URL = 'http://localhost:4000/api';

// Helper function to get auth headers
const getAuthHeaders = (token) => ({
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
});

// User API calls
export const userAPI = {
    // Register user
    register: async (userData) => {
        const response = await fetch(`${API_BASE_URL}/user/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(userData)
        });
        return response.json();
    },

    // Login user
    login: async (credentials) => {
        const response = await fetch(`${API_BASE_URL}/user/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(credentials)
        });
        return response.json();
    },

    // Get user profile
    getProfile: async (token) => {
        const response = await fetch(`${API_BASE_URL}/user/get-profile`, {
            method: 'GET',
            headers: getAuthHeaders(token)
        });
        return response.json();
    },

    // Update user profile
    updateProfile: async (token, profileData) => {
        const formData = new FormData();
        Object.keys(profileData).forEach(key => {
            if (key === 'address') {
                formData.append(key, JSON.stringify(profileData[key]));
            } else if (key === 'image' && profileData[key]) {
                formData.append(key, profileData[key]);
            } else {
                formData.append(key, profileData[key]);
            }
        });

        const response = await fetch(`${API_BASE_URL}/user/update-profile`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${token}` },
            body: formData
        });
        return response.json();
    },

    // Book appointment
    bookAppointment: async (token, appointmentData) => {
        // Ensure amount is included in the appointment data
        const appointmentPayload = {
            ...appointmentData,
            amount: appointmentData.amount || appointmentData.doctor?.fees || 0
        };
        
        console.log('Booking appointment with data:', appointmentPayload);
        
        const response = await fetch(`${API_BASE_URL}/user/book-appointment`, {
            method: 'POST',
            headers: getAuthHeaders(token),
            body: JSON.stringify(appointmentPayload)
        });
        return response.json();
    },

    // Get user appointments
    getAppointments: async (token) => {
        const response = await fetch(`${API_BASE_URL}/user/appointments`, {
            method: 'GET',
            headers: getAuthHeaders(token)
        });
        return response.json();
    },

    // Cancel appointment
    cancelAppointment: async (token, appointmentId) => {
        const response = await fetch(`${API_BASE_URL}/user/cancel-appointment`, {
            method: 'POST',
            headers: getAuthHeaders(token),
            body: JSON.stringify({ appointmentId })
        });
        return response.json();
    }
};

// Doctor API calls
export const doctorAPI = {
    // Get all doctors
    getAllDoctors: async () => {
        const response = await fetch(`${API_BASE_URL}/doctor/list`);
        return response.json();
    },

    // Get doctors by specialization
    getDoctorsBySpecialization: async (specialization) => {
        const url = specialization && specialization !== 'all' 
            ? `${API_BASE_URL}/doctor/filter?specialization=${encodeURIComponent(specialization)}`
            : `${API_BASE_URL}/doctor/list`;
        
        const response = await fetch(url);
        return response.json();
    },

    // Login doctor
    login: async (credentials) => {
        const response = await fetch(`${API_BASE_URL}/doctor/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(credentials)
        });
        return response.json();
    },

    // Get doctor appointments
    getAppointments: async (token) => {
        const response = await fetch(`${API_BASE_URL}/doctor/appointments`, {
            method: 'GET',
            headers: getAuthHeaders(token)
        });
        return response.json();
    },

    // Get doctor profile
    getProfile: async (token) => {
        const response = await fetch(`${API_BASE_URL}/doctor/profile`, {
            method: 'GET',
            headers: getAuthHeaders(token)
        });
        return response.json();
    },

    // Update doctor profile
    updateProfile: async (token, profileData) => {
        const response = await fetch(`${API_BASE_URL}/doctor/update-profile`, {
            method: 'POST',
            headers: getAuthHeaders(token),
            body: JSON.stringify(profileData)
        });
        return response.json();
    },

    // Change availability
    changeAvailability: async (token, available) => {
        const response = await fetch(`${API_BASE_URL}/doctor/change-availability`, {
            method: 'POST',
            headers: getAuthHeaders(token),
            body: JSON.stringify({ available })
        });
        return response.json();
    },

    // Complete appointment
    completeAppointment: async (token, appointmentId) => {
        const response = await fetch(`${API_BASE_URL}/doctor/complete-appointment`, {
            method: 'POST',
            headers: getAuthHeaders(token),
            body: JSON.stringify({ appointmentId })
        });
        return response.json();
    },

    // Get doctor dashboard
    getDashboard: async (token) => {
        const response = await fetch(`${API_BASE_URL}/doctor/dashboard`, {
            method: 'GET',
            headers: getAuthHeaders(token)
        });
        return response.json();
    }
};

// Admin API calls
export const adminAPI = {
    // Login admin
    login: async (credentials) => {
        const response = await fetch(`${API_BASE_URL}/admin/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(credentials)
        });
        return response.json();
    },

    // Add doctor
    addDoctor: async (token, doctorData) => {
        const formData = new FormData();
        Object.keys(doctorData).forEach(key => {
            if (key === 'address') {
                formData.append(key, JSON.stringify(doctorData[key]));
            } else if (key === 'image' && doctorData[key]) {
                formData.append(key, doctorData[key]);
            } else {
                formData.append(key, doctorData[key]);
            }
        });

        const response = await fetch(`${API_BASE_URL}/admin/add-doctor`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${token}` },
            body: formData
        });
        return response.json();
    },

    // Get all doctors
    getAllDoctors: async (token) => {
        const response = await fetch(`${API_BASE_URL}/admin/all-doctors`, {
            method: 'GET',
            headers: getAuthHeaders(token)
        });
        return response.json();
    },

    // Get all appointments
    getAppointments: async (token) => {
        const response = await fetch(`${API_BASE_URL}/admin/appointments`, {
            method: 'GET',
            headers: getAuthHeaders(token)
        });
        return response.json();
    },

    // Get admin dashboard
    getDashboard: async (token) => {
        const response = await fetch(`${API_BASE_URL}/admin/dashboard`, {
            method: 'GET',
            headers: getAuthHeaders(token)
        });
        return response.json();
    }
};

// Payment API calls
export const paymentAPI = {
    // Razorpay payment
    createRazorpayOrder: async (token, appointmentId) => {
        const response = await fetch(`${API_BASE_URL}/user/payment-razorpay`, {
            method: 'POST',
            headers: getAuthHeaders(token),
            body: JSON.stringify({ appointmentId })
        });
        return response.json();
    },

    // Verify Razorpay payment
    verifyRazorpay: async (token, paymentData) => {
        const response = await fetch(`${API_BASE_URL}/user/verifyRazorpay`, {
            method: 'POST',
            headers: getAuthHeaders(token),
            body: JSON.stringify(paymentData)
        });
        return response.json();
    },

    // Stripe payment
    createStripeSession: async (token, appointmentId) => {
        const response = await fetch(`${API_BASE_URL}/user/payment-stripe`, {
            method: 'POST',
            headers: getAuthHeaders(token),
            body: JSON.stringify({ appointmentId })
        });
        return response.json();
    },

    // Verify Stripe payment
    verifyStripe: async (token, paymentData) => {
        const response = await fetch(`${API_BASE_URL}/user/verifyStripe`, {
            method: 'POST',
            headers: getAuthHeaders(token),
            body: JSON.stringify(paymentData)
        });
        return response.json();
    }
};
