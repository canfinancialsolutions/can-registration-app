import RegistrationForm from "./components/RegistrationForm.jsx";

export default function App() {
  return (
    <div className="page">
      <RegistrationForm />
      <footer className="footer">
        <span>©{new Date().getFullYear()} AnuNathan Financial Group</span>
      </footer>
    </div>
  );
}
