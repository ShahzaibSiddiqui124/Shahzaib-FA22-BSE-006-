import React, { useState } from 'react';
import { userAPI } from './frontend-api-calls';

const AppointmentBookingComponent = ({ selectedDoctor, userToken, onBookingSuccess, onBookingCancel }) => {
    const [formData, setFormData] = useState({
        slotDate: '',
        slotTime: '',
        amount: selectedDoctor?.fees || 0
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [success, setSuccess] = useState(false);

    // Available time slots
    const timeSlots = [
        '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
        '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
        '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
        '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM'
    ];

    // Get today's date and next 30 days
    const getAvailableDates = () => {
        const dates = [];
        const today = new Date();
        
        for (let i = 0; i < 30; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() + i);
            dates.push(date.toISOString().split('T')[0]);
        }
        
        return dates;
    };

    // Handle form input changes
    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
        
        // Clear error when user starts typing
        if (error) setError(null);
    };

    // Handle form submission
    const handleSubmit = async (e) => {
        e.preventDefault();
        
        if (!selectedDoctor) {
            setError('Please select a doctor first');
            return;
        }

        if (!formData.slotDate || !formData.slotTime) {
            setError('Please select both date and time');
            return;
        }

        setLoading(true);
        setError(null);

        try {
            const appointmentData = {
                docId: selectedDoctor._id,
                slotDate: formData.slotDate,
                slotTime: formData.slotTime,
                amount: selectedDoctor.fees,
                doctor: selectedDoctor // Include full doctor object for fallback
            };

            console.log('Sending appointment data:', appointmentData);
            const response = await userAPI.bookAppointment(userToken, appointmentData);

            if (response.success) {
                setSuccess(true);
                setTimeout(() => {
                    onBookingSuccess && onBookingSuccess(response);
                }, 2000);
            } else {
                setError(response.message || 'Failed to book appointment');
            }
        } catch (err) {
            setError('Network error. Please try again.');
            console.error('Error booking appointment:', err);
        } finally {
            setLoading(false);
        }
    };

    // Handle cancel
    const handleCancel = () => {
        onBookingCancel && onBookingCancel();
    };

    if (success) {
        return (
            <div className="booking-success">
                <div className="success-icon">✓</div>
                <h3>Appointment Booked Successfully!</h3>
                <p>Your appointment has been confirmed.</p>
                <button onClick={handleCancel} className="btn-primary">
                    Close
                </button>
            </div>
        );
    }

    return (
        <div className="appointment-booking">
            <div className="booking-header">
                <h2>Book Appointment</h2>
                {selectedDoctor && (
                    <div className="selected-doctor">
                        <h3>Dr. {selectedDoctor.name}</h3>
                        <p>{selectedDoctor.speciality} • {selectedDoctor.degree}</p>
                        <p>Consultation Fee: ₹{selectedDoctor.fees}</p>
                    </div>
                )}
            </div>

            <form onSubmit={handleSubmit} className="booking-form">
                {/* Date Selection */}
                <div className="form-group">
                    <label htmlFor="slotDate" className="form-label">
                        Select Date *
                    </label>
                    <select
                        id="slotDate"
                        name="slotDate"
                        value={formData.slotDate}
                        onChange={handleInputChange}
                        className="form-select"
                        required
                    >
                        <option value="">Choose a date</option>
                        {getAvailableDates().map(date => (
                            <option key={date} value={date}>
                                {new Date(date).toLocaleDateString('en-US', {
                                    weekday: 'long',
                                    year: 'numeric',
                                    month: 'long',
                                    day: 'numeric'
                                })}
                            </option>
                        ))}
                    </select>
                </div>

                {/* Time Selection */}
                <div className="form-group">
                    <label htmlFor="slotTime" className="form-label">
                        Select Time *
                    </label>
                    <select
                        id="slotTime"
                        name="slotTime"
                        value={formData.slotTime}
                        onChange={handleInputChange}
                        className="form-select"
                        required
                    >
                        <option value="">Choose a time</option>
                        {timeSlots.map(time => (
                            <option key={time} value={time}>
                                {time}
                            </option>
                        ))}
                    </select>
                </div>

                {/* Amount Display */}
                <div className="form-group">
                    <label className="form-label">Consultation Fee</label>
                    <div className="amount-display">
                        ₹{selectedDoctor?.fees || 0}
                    </div>
                </div>

                {/* Error Message */}
                {error && (
                    <div className="error-message">
                        {error}
                    </div>
                )}

                {/* Action Buttons */}
                <div className="form-actions">
                    <button
                        type="button"
                        onClick={handleCancel}
                        className="btn-secondary"
                        disabled={loading}
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        className="btn-primary"
                        disabled={loading || !selectedDoctor}
                    >
                        {loading ? 'Booking...' : 'Book Appointment'}
                    </button>
                </div>
            </form>
        </div>
    );
};

export default AppointmentBookingComponent;
