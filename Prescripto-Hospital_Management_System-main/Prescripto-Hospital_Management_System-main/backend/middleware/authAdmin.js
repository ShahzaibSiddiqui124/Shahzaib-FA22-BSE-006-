import jwt from "jsonwebtoken"

// Admin Authentication Middleware (DEBUG MODE)
const authAdmin = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        
        // Log 1: Check if header exists
        console.log("--- AUTH DEBUG START ---");
        console.log("1. Received Header:", authHeader);

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            console.log("ERROR: Missing or bad header");
            return res.json({ success: false, message: 'Not Authorized Login Again' })
        }
        
        const token = authHeader.substring(7); 
        const token_decode = jwt.verify(token, process.env.JWT_SECRET)

        // Log 2: Check what is inside the token
        console.log("2. Decoded Token:", token_decode);
        
        // Log 3: Check what is in the .env file
        console.log("3. Server Expects Email:", process.env.ADMIN_EMAIL);
        console.log("4. Server Expects Pass:", process.env.ADMIN_PASSWORD);

        // Log 4: Check the exact comparison
        const emailMatch = token_decode.email === process.env.ADMIN_EMAIL;
        const passMatch = token_decode.password === process.env.ADMIN_PASSWORD;
        console.log(`5. Match Results -> Email: ${emailMatch}, Password: ${passMatch}`);
        console.log("--- AUTH DEBUG END ---");

        if (!emailMatch || !passMatch) {
            return res.json({ success: false, message: 'Not Authorized Login Again' })
        }
        
        next()

    } catch (error) {
        console.log("AUTH ERROR:", error)
        res.json({ success: false, message: error.message })
    }
}

export default authAdmin;