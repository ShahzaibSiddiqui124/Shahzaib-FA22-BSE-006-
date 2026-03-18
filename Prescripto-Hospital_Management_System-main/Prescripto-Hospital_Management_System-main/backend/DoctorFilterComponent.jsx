import React, { useState, useEffect } from 'react';
import { doctorAPI } from './frontend-api-calls';

const DoctorFilterComponent = ({ onDoctorSelect, selectedSpecialization, onSpecializationChange }) => {
    const [doctors, setDoctors] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    // Specialization options
    const specializations = [
        'all',
        'Cardiology',
        'Dermatology',
        'Neurology',
        'Orthopedics',
        'Pediatrics',
        'Gynecology',
        'General Medicine',
        'Psychiatry',
        'Ophthalmology',
        'ENT',
        'Urology',
        'Gastroenterology',
        'Pulmonology',
        'Endocrinology'
    ];

    // Fetch doctors based on specialization
    const fetchDoctors = async (specialization = 'all') => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await doctorAPI.getDoctorsBySpecialization(specialization);
            
            if (response.success) {
                setDoctors(response.doctors);
            } else {
                setError(response.message || 'Failed to fetch doctors');
            }
        } catch (err) {
            setError('Network error. Please try again.');
            console.error('Error fetching doctors:', err);
        } finally {
            setLoading(false);
        }
    };

    // Load doctors on component mount and when specialization changes
    useEffect(() => {
        fetchDoctors(selectedSpecialization);
    }, [selectedSpecialization]);

    // Handle specialization change
    const handleSpecializationChange = (e) => {
        const newSpecialization = e.target.value;
        onSpecializationChange(newSpecialization);
    };

    // Handle doctor selection
    const handleDoctorSelect = (doctor) => {
        onDoctorSelect(doctor);
    };

    return (
        <div className="doctor-filter-container">
            {/* Specialization Filter */}
            <div className="filter-section">
                <label htmlFor="specialization-filter" className="filter-label">
                    Filter by Specialization:
                </label>
                <select
                    id="specialization-filter"
                    value={selectedSpecialization}
                    onChange={handleSpecializationChange}
                    className="specialization-select"
                >
                    {specializations.map(spec => (
                        <option key={spec} value={spec}>
                            {spec === 'all' ? 'All Specializations' : spec}
                        </option>
                    ))}
                </select>
            </div>

            {/* Loading State */}
            {loading && (
                <div className="loading-state">
                    <div className="spinner"></div>
                    <p>Loading doctors...</p>
                </div>
            )}

            {/* Error State */}
            {error && (
                <div className="error-state">
                    <p className="error-message">{error}</p>
                    <button 
                        onClick={() => fetchDoctors(selectedSpecialization)}
                        className="retry-button"
                    >
                        Retry
                    </button>
                </div>
            )}

            {/* Doctors List */}
            {!loading && !error && (
                <div className="doctors-list">
                    {doctors.length === 0 ? (
                        <div className="no-doctors">
                            <p>No doctors found for the selected specialization.</p>
                        </div>
                    ) : (
                        <div className="doctors-grid">
                            {doctors.map(doctor => (
                                <div 
                                    key={doctor._id} 
                                    className={`doctor-card ${!doctor.available ? 'unavailable' : ''}`}
                                    onClick={() => doctor.available && handleDoctorSelect(doctor)}
                                >
                                    <div className="doctor-image">
                                        <img 
                                            src={doctor.image} 
                                            alt={doctor.name}
                                            onError={(e) => {
                                                e.target.src = '/default-doctor.png';
                                            }}
                                        />
                                    </div>
                                    <div className="doctor-info">
                                        <h3 className="doctor-name">{doctor.name}</h3>
                                        <p className="doctor-speciality">{doctor.speciality}</p>
                                        <p className="doctor-degree">{doctor.degree}</p>
                                        <p className="doctor-experience">{doctor.experience} experience</p>
                                        <p className="doctor-fees">₹{doctor.fees} consultation fee</p>
                                        <div className="doctor-status">
                                            <span className={`status-badge ${doctor.available ? 'available' : 'unavailable'}`}>
                                                {doctor.available ? 'Available' : 'Unavailable'}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            )}
        </div>
    );
};

export default DoctorFilterComponent;
