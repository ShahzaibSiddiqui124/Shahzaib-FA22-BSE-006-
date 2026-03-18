import React, { useState } from 'react';
import DoctorFilterComponent from './DoctorFilterComponent';
import AppointmentBookingComponent from './AppointmentBookingComponent';
import './DoctorBookingPage.css';

const DoctorBookingPage = ({ userToken }) => {
    const [selectedDoctor, setSelectedDoctor] = useState(null);
    const [selectedSpecialization, setSelectedSpecialization] = useState('all');
    const [showBookingForm, setShowBookingForm] = useState(false);

    // Handle doctor selection
    const handleDoctorSelect = (doctor) => {
        setSelectedDoctor(doctor);
        setShowBookingForm(true);
    };

    // Handle specialization change
    const handleSpecializationChange = (specialization) => {
        setSelectedSpecialization(specialization);
        setSelectedDoctor(null);
        setShowBookingForm(false);
    };

    // Handle booking success
    const handleBookingSuccess = (response) => {
        console.log('Appointment booked successfully:', response);
        // Reset form
        setSelectedDoctor(null);
        setShowBookingForm(false);
        // You can add a success notification here
        alert('Appointment booked successfully!');
    };

    // Handle booking cancel
    const handleBookingCancel = () => {
        setShowBookingForm(false);
        setSelectedDoctor(null);
    };

    return (
        <div className="doctor-booking-page">
            <div className="page-header">
                <h1>Find & Book a Doctor</h1>
                <p>Select a specialization and choose your preferred doctor</p>
            </div>

            <div className="booking-container">
                {/* Doctor Filter Section */}
                <div className="filter-section">
                    <DoctorFilterComponent
                        onDoctorSelect={handleDoctorSelect}
                        selectedSpecialization={selectedSpecialization}
                        onSpecializationChange={handleSpecializationChange}
                    />
                </div>

                {/* Booking Form Section */}
                {showBookingForm && selectedDoctor && (
                    <div className="booking-section">
                        <AppointmentBookingComponent
                            selectedDoctor={selectedDoctor}
                            userToken={userToken}
                            onBookingSuccess={handleBookingSuccess}
                            onBookingCancel={handleBookingCancel}
                        />
                    </div>
                )}
            </div>
        </div>
    );
};

export default DoctorBookingPage;
