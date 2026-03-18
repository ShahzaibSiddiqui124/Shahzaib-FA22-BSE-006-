import multer from "multer";

const storage = multer.diskStorage({
    // ✅ 1. Define where to save the files
    destination: function (req, file, callback) {
        callback(null, 'uploads/') // Files will be saved in 'backend/uploads'
    },
    // ✅ 2. Define how to name the files (Timestamp + Name)
    filename: function (req, file, callback) {
        callback(null, Date.now() + '-' + file.originalname)
    }
});

const upload = multer({ storage: storage })

export default upload