importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

// Dummy config to prevent crash, you can replace with your actual config if needed
const firebaseConfig = {
  apiKey: "AIzaSyB4Te02AObkjF-vECNXAKbgQouLYfy6mRM",
  authDomain: "app-movie-df089.firebaseapp.com",
  projectId: "app-movie-df089",
  storageBucket: "app-movie-df089.firebasestorage.app",
  messagingSenderId: "422110889291",
  appId: "1:422110889291:web:6a7ce363d9ea32de52d4ce",
  measurementId: "G-4MDHV92PRG"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();
