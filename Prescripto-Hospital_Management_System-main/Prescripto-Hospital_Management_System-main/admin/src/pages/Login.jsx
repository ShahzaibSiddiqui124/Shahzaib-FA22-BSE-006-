import axios from 'axios'
import React, { useContext, useState } from 'react'
import { DoctorContext } from '../context/DoctorContext'
import { AdminContext } from '../context/AdminContext'
import { toast } from 'react-toastify'

const Login = () => {

  const [state, setState] = useState('Admin')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  const backendUrl = import.meta.env.VITE_BACKEND_URL

  const { setDToken } = useContext(DoctorContext)
  const { setAToken } = useContext(AdminContext)

  const onSubmitHandler = async (event) => {
    event.preventDefault();

    // 1. Log to prove the button was clicked
    console.log("Login form submitted");
    console.log("Current State:", state);
    console.log("Backend URL:", backendUrl); 

    try {

      if (state === 'Admin') {

        // 2. Log before the request
        console.log("Sending Admin Login Request...");
        
        const { data } = await axios.post(backendUrl + '/api/admin/login', { email, password })
        
        // 3. Log the response
        console.log("Admin Login Response:", data);

        if (data.success) {
          localStorage.setItem('aToken', data.token)
          setAToken(data.token)
          toast.success("Login Successful") // Added visual feedback
        } else {
          toast.error(data.message)
        }

      } else {

        console.log("Sending Doctor Login Request...");
        
        const { data } = await axios.post(backendUrl + '/api/doctor/login', { email, password })
        
        console.log("Doctor Login Response:", data);

        if (data.success) {
          localStorage.setItem('dToken', data.token)
          setDToken(data.token)
          toast.success("Login Successful")
        } else {
          toast.error(data.message)
        }

      }

    } catch (error) {
      // 4. THIS IS THE MISSING PART THAT FIXES THE "SILENT FAIL"
      console.log("Login Error:", error);
      toast.error(error.message);
    }
  }

  return (
    <form onSubmit={onSubmitHandler} className='min-h-[80vh] flex items-center'>
      <div className='flex flex-col gap-3 m-auto items-start p-8 min-w-[340px] sm:min-w-96 border rounded-xl text-[#5E5E5E] text-sm shadow-lg'>
        <p className='text-2xl font-semibold m-auto'><span className='text-primary'>{state}</span> Login</p>
        <div className='w-full '>
          <p>Email</p>
          <input onChange={(e) => setEmail(e.target.value)} value={email} className='border border-[#DADADA] rounded w-full p-2 mt-1' type="email" required />
        </div>
        <div className='w-full '>
          <p>Password</p>
          <input onChange={(e) => setPassword(e.target.value)} value={password} className='border border-[#DADADA] rounded w-full p-2 mt-1' type="password" required />
        </div>
        <button className='bg-primary text-white w-full py-2 rounded-md text-base'>Login</button>
        {
          state === 'Admin'
            ? <p>Doctor Login? <span onClick={() => setState('Doctor')} className='text-primary underline cursor-pointer'>Click here</span></p>
            : <p>Admin Login? <span onClick={() => setState('Admin')} className='text-primary underline cursor-pointer'>Click here</span></p>
        }
      </div>
    </form>
  )
}

export default Login