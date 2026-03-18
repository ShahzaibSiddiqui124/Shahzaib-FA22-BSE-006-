import { createContext, useEffect, useState } from "react";
import { toast } from "react-toastify";
import axios from 'axios'

export const AppContext = createContext()

const AppContextProvider = (props) => {

    const currencySymbol = '₹'
    const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:5000'
    
    // Debug: Log backend URL
    console.log('Backend URL:', backendUrl)

    const [doctors, setDoctors] = useState([])
    const [token, setToken] = useState(localStorage.getItem('token') ? localStorage.getItem('token') : '')
    const [userData, setUserData] = useState(false)

    // Getting Doctors using API
    const getDoctosData = async () => {

        try {
            console.log('Fetching doctors from:', backendUrl + '/api/doctor/list')
            const { data } = await axios.get(backendUrl + '/api/doctor/list')
            console.log('Doctors API response:', data)
            if (data.success) {
                setDoctors(data.doctors)
            } else {
                toast.error(data.message || 'Failed to fetch doctors')
            }

        } catch (error) {
            console.error('Error fetching doctors:', error)
            if (error.response) {
                console.error('Response data:', error.response.data)
                console.error('Response status:', error.response.status)
                toast.error(`API Error: ${error.response.data?.message || error.message}`)
            } else if (error.request) {
                console.error('Request error:', error.request)
                toast.error('Network Error: Unable to connect to backend server')
            } else {
                toast.error(`Error: ${error.message}`)
            }
        }

    }

    // Getting User Profile using API
    const loadUserProfileData = async () => {

        try {
            console.log('Fetching user profile from:', backendUrl + '/api/user/get-profile')
            const { data } = await axios.get(backendUrl + '/api/user/get-profile', { headers: { Authorization: `Bearer ${token}` } })
            console.log('User profile API response:', data)

            if (data.success) {
                setUserData(data.userData)
            } else {
                toast.error(data.message || 'Failed to fetch user profile')
            }

        } catch (error) {
            console.error('Error fetching user profile:', error)
            if (error.response) {
                console.error('Response data:', error.response.data)
                console.error('Response status:', error.response.status)
                if (error.response.status === 401) {
                    toast.error('Authentication failed. Please login again.')
                    setToken('')
                    localStorage.removeItem('token')
                } else {
                    toast.error(`API Error: ${error.response.data?.message || error.message}`)
                }
            } else if (error.request) {
                console.error('Request error:', error.request)
                toast.error('Network Error: Unable to connect to backend server')
            } else {
                toast.error(`Error: ${error.message}`)
            }
        }

    }

    useEffect(() => {
        getDoctosData()
    }, [])

    useEffect(() => {
        if (token) {
            loadUserProfileData()
        }
    }, [token])

    const value = {
        doctors, getDoctosData,
        currencySymbol,
        backendUrl,
        token, setToken,
        userData, setUserData, loadUserProfileData
    }

    return (
        <AppContext.Provider value={value}>
            {props.children}
        </AppContext.Provider>
    )

}

export default AppContextProvider
