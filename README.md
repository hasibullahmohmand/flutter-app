# 🧴 Skin Disease Prediction App

A responsive Flutter mobile application developed as part of a university-led project under faculty mentorship. The app supports early-stage skin disease data collection and image review by medical professionals to build a high-quality dataset for training an AI prediction model.

## 🚀 Project Overview

This app streamlines the workflow for collecting and approving skin disease images. It enables:

- User registration and login via REST APIs  
- Image uploading (camera/gallery)  
- Doctor review and approval of submitted images  
- Clean and intuitive UI/UX for both patients and medical professionals  
- Backend-ready integration for future AI model training

## 🛠️ Features

- 📱 **User Authentication** – Secure sign-up and login system using API calls  
- 🖼️ **Image Uploading** – Users can upload or capture square-format skin images  
- 👨‍⚕️ **Doctor Interface** – Doctors can view pending images, approve/reject them, and provide descriptions  
- 🧠 **AI Dataset Pipeline** – Approved images are tagged and stored for later use in machine learning  
- 🎨 **Clean UI/UX** – Built with usability and scalability in mind, using best practices in Flutter

## 🧩 Tech Stack

- **Frontend**: Flutter (Dart)  
- **Backend**: Custom REST APIs (not included in this repo)  
- **Authentication**: Email/Password via API  
- **Image Handling**: File picker and camera access  

## 📁 Project Structure

```
lib/
│
├── screens/           # UI screens (Login, Register, Pending, Approved, etc.)
└── main.dart          # App entry point
```

## 🔮 Future Work

- Integration of AI model for real-time skin disease prediction  
- Role-based access control (RBAC) for doctors and patients  
- Admin dashboard and analytics  
- Multi-language support  

## 👥 Team & Contribution

- **Frontend Developer**: Hasibullah Mohmand – Focused on UI development, API integration, and user workflows  
- **Backend Developer**: Aboubacar Sow – Backend development  
- **Mentorship**: Guided by Samet Diri, Kocaeli University

## 📌 How to Run

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/skin-disease-predictor.git
   cd skin-disease-predictor
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

4. Ensure your backend API server is running and accessible.

---

*Developed with ❤️ under university mentorship.*
