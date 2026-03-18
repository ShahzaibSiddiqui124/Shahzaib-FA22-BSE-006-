import React, { useState, useEffect } from 'react';
import { userAPI, doctorAPI } from './frontend-api-calls';
import DoctorBookingPage from './DoctorBookingPage';

const FrontendIntegrationExample = () => {
    const [userToken, setUserToken] = useState(null);
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    // Check if user is already logged in
    useEffect(() => {
        const token = localStorage.getItem('userToken');
        if (token) {
            setUserToken(token);
            loadUserProfile(token);
        }
    }, []);

    // Load user profile
    const loadUserProfile = async (token) => {
        try {
            const response = await userAPI.getProfile(token);
            if (response.success) {
                setUser(response.userData);
            } else {
                // Token might be invalid, clear it
                localStorage.removeItem('userToken');
                setUserToken(null);
            }
        } catch (err) {
            console.error('Error loading user profile:', err);
            localStorage.removeItem('userToken');
            setUserToken(null);
        }
    };

    // Handle login
    const handleLogin = async (credentials) => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await userAPI.login(credentials);
            if (response.success) {
                setUserToken(response.token);
                localStorage.setItem('userToken', response.token);
                await loadUserProfile(response.token);
            } else {
                setError(response.message);
            }
        } catch (err) {
            setError('Login failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    // Handle registration
    const handleRegister = async (userData) => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await userAPI.register(userData);
            if (response.success) {
                setUserToken(response.token);
                localStorage.setItem('userToken', response.token);
                await loadUserProfile(response.token);
            } else {
                setError(response.message);
            }
        } catch (err) {
            setError('Registration failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    // Handle logout
    const handleLogout = () => {
        setUserToken(null);
        setUser(null);
        localStorage.removeItem('userToken');
    };

    // Handle appointment booking success
    const handleBookingSuccess = (response) => {
        console.log('Appointment booked successfully:', response);
        // You can add a success notification here
        alert('Appointment booked successfully!');
    };

    // If user is not logged in, show login/register form
    if (!userToken) {
        return (
            <div className="auth-container">
                <div className="auth-form">
                    <h2>Welcome to Prescripto</h2>
                    <p>Please login or register to book appointments</p>
                    
                    {error && (
                        <div className="error-message">
                            {error}
                        </div>
                    )}
                    
                    <div className="auth-buttons">
                        <button 
                            onClick={() => handleLogin({
                                email: 'test@example.com',
                                password: 'password123'
                            })}
                            disabled={loading}
                            className="btn-primary"
                        >
                            {loading ? 'Logging in...' : 'Login as Test User'}
                        </button>
                        
                        <button 
                            onClick={() => handleRegister({
                                name: 'New User',
                                email: 'newuser@example.com',
                                password: 'password123'
                            })}
                            disabled={loading}
                            className="btn-secondary"
                        >
                            {loading ? 'Registering...' : 'Register New User'}
                        </button>
                    </div>
                </div>
            </div>
        );
    }

    // If user is logged in, show the booking page
    return (
        <div className="app-container">
            <header className="app-header">
                <h1>Prescripto - Hospital Management System</h1>
                <div className="user-info">
                    <span>Welcome, {user?.name}</span>
                    <button onClick={handleLogout} className="btn-logout">
                        Logout
                    </button>
                </div>
            </header>
            
            <main className="app-main">
                <DoctorBookingPage 
                    userToken={userToken}
                    onBookingSuccess={handleBookingSuccess}
                />
            </main>
        </div>
    );
};

export default FrontendIntegrationExample;
