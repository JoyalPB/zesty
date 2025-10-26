import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { setDoc, doc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Separator } from "@/components/ui/separator";
import { useToast } from "@/hooks/use-toast";
import { Mail, Lock, User, Phone, CheckCircle, XCircle, ArrowRight } from "lucide-react";

// Password Criteria Checklist
const PasswordCriteria = ({ criteria }) => (
  <div className="grid grid-cols-1 sm:grid-cols-2 gap-1 text-xs text-muted-foreground mt-2">
    {Object.entries(criteria).map(([key, value]) => (
      <div key={key} className={`flex items-center transition-colors ${value ? 'text-green-500' : 'text-muted-foreground'}`}>
        {value ? <CheckCircle className="w-3.5 h-3.5 mr-2" /> : <XCircle className="w-3.5 h-3.5 mr-2" />}
        <span>{key}</span>
      </div>
    ))}
  </div>
);

const Register = () => {
  const [formData, setFormData] = useState({
    firstName: "", lastName: "", email: "", phone: "", password: "", confirmPassword: ""
  });
  const [errors, setErrors] = useState({});
  const [acceptTerms, setAcceptTerms] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();

  // Password criteria state
  const [passwordCriteria, setPasswordCriteria] = useState({
    'At least 8 characters': false,
    'One uppercase letter': false,
    'One lowercase letter': false,
    'One number': false,
    'One special character': false,
  });

  useEffect(() => {
    const { password } = formData;
    setPasswordCriteria({
      'At least 8 characters': password.length >= 8,
      'One uppercase letter': /[A-Z]/.test(password),
      'One lowercase letter': /[a-z]/.test(password),
      'One number': /[0-9]/.test(password),
      'One special character': /[\W_]/.test(password),
    });
  }, [formData.password]);

  // Input change
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    validateField(name, value);
  };

  // Field validation
  const validateField = (name, value) => {
    let error = "";
    switch (name) {
      case "firstName":
        if (!value) error = "First name is required";
        else if (!/^[a-zA-Z]+$/.test(value)) error = "Only letters allowed";
        break;
      case "lastName":
        if (!value) error = "Last name is required";
        else if (!/^[a-zA-Z]+$/.test(value)) error = "Only letters allowed";
        break;
      case "email":
        if (!value) error = "Email is required";
        else if (!/\S+@\S+\.\S+/.test(value)) error = "Invalid email address";
        break;
      case "phone":
        if (!value) error = "Phone is required";
        else if (!/^\d{10}$/.test(value)) error = "Must be a 10-digit number";
        break;
      case "confirmPassword":
        if (!value) error = "Please confirm your password";
        else if (value !== formData.password) error = "Passwords must match";
        break;
      default:
        break;
    }
    setErrors(prev => ({ ...prev, [name]: error }));
  };

  // Validate form
  const validateForm = () => {
    const newErrors = {};
    if (!formData.firstName) newErrors.firstName = "First name is required";
    else if (!/^[a-zA-Z]+$/.test(formData.firstName)) newErrors.firstName = "Only letters allowed";

    if (!formData.lastName) newErrors.lastName = "Last name is required";
    else if (!/^[a-zA-Z]+$/.test(formData.lastName)) newErrors.lastName = "Only letters allowed";

    if (!formData.email) newErrors.email = "Email is required";
    else if (!/\S+@\S+\.\S+/.test(formData.email)) newErrors.email = "Invalid email address";

    if (!formData.phone) newErrors.phone = "Phone is required";
    else if (!/^\d{10}$/.test(formData.phone)) newErrors.phone = "Must be a 10-digit number";

    if (!formData.password) newErrors.password = "Password is required";
    else if (!Object.values(passwordCriteria).every(Boolean)) newErrors.password = "Password does not meet all criteria";

    if (!formData.confirmPassword) newErrors.confirmPassword = "Please confirm your password";
    else if (formData.password !== formData.confirmPassword) newErrors.confirmPassword = "Passwords must match";

    if (!acceptTerms) newErrors.terms = "You must accept terms";

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Register handler
  const handleRegister = async (e) => {
    e.preventDefault();
    if (!validateForm()) {
      toast({ title: "Registration Error ⚠️", description: "Please fix the errors.", variant: "destructive" });
      return;
    }

    setLoading(true);
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, formData.email, formData.password);
      const user = userCredential.user;

      // Save staff profile (no displayName)
      await setDoc(doc(db, "staff", user.uid), {
        uid: user.uid,
        email: user.email,
        firstName: formData.firstName,
        lastName: formData.lastName,
        phone: formData.phone,
        createdAt: new Date(),
      });

      toast({ title: "Success! ✅", description: "Account created successfully." });
      navigate("/");
    } catch (error) {
      let errorMessage = "An unexpected error occurred";
      if (error.code === "auth/email-already-in-use") errorMessage = "This email is already registered";
      toast({ title: "Registration Failed ⚠️", description: errorMessage, variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-background via-muted to-background px-4">
      <div className="w-full max-w-lg">
        <Card className="backdrop-blur-xl bg-card/70 border border-border/40 shadow-2xl rounded-2xl">
          <CardHeader className="text-center space-y-3 pb-6">

            {/* Logo */}
            <img
              src="/zesty-logo.png"
              alt="Zesty Logo"
              className="mx-auto w-32 h-32 object-contain"
            />
            <div className="space-y-1">
              <CardTitle className="text-3xl font-extrabold bg-gradient-to-r from-primary to-purple-500 bg-clip-text text-transparent">
                Create Account
              </CardTitle>
              <CardDescription className="text-base text-muted-foreground">
                Join us and start your journey with <span className="font-medium text-foreground">Zesty</span>
              </CardDescription>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            <form onSubmit={handleRegister} className="space-y-6">
              {/* Name fields */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="firstName">First Name</Label>
                  <div className="relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground w-5 h-5" />
                    <Input
                      id="firstName"
                      name="firstName"
                      value={formData.firstName}
                      onChange={handleChange}
                      placeholder="John"
                      className={`pl-10 h-12 rounded-xl ${errors.firstName ? 'border-destructive' : ''}`}
                    />
                  </div>
                  {errors.firstName && <p className="text-xs text-destructive">{errors.firstName}</p>}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lastName">Last Name</Label>
                  <div className="relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground w-5 h-5" />
                    <Input
                      id="lastName"
                      name="lastName"
                      value={formData.lastName}
                      onChange={handleChange}
                      placeholder="Doe"
                      className={`pl-10 h-12 rounded-xl ${errors.lastName ? 'border-destructive' : ''}`}
                    />
                  </div>
                  {errors.lastName && <p className="text-xs text-destructive">{errors.lastName}</p>}
                </div>
              </div>

              {/* Email */}
              <div className="space-y-2">
                <Label htmlFor="email">Email Address</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground w-5 h-5" />
                  <Input
                    id="email"
                    name="email"
                    type="email"
                    value={formData.email}
                    onChange={handleChange}
                    placeholder="you@example.com"
                    className={`pl-10 h-12 rounded-xl ${errors.email ? 'border-destructive' : ''}`}
                  />
                </div>
                {errors.email && <p className="text-xs text-destructive">{errors.email}</p>}
              </div>

              {/* Phone */}
              <div className="space-y-2">
                <Label htmlFor="phone">Phone Number</Label>
                <div className="relative">
                  <Phone className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground w-5 h-5" />
                  <Input
                    id="phone"
                    name="phone"
                    type="tel"
                    value={formData.phone}
                    onChange={handleChange}
                    placeholder="9876543210"
                    className={`pl-10 h-12 rounded-xl ${errors.phone ? 'border-destructive' : ''}`}
                  />
                </div>
                {errors.phone && <p className="text-xs text-destructive">{errors.phone}</p>}
              </div>

              {/* Password */}
              <div className="space-y-2">
                <Label htmlFor="password">Password</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground w-5 h-5" />
                  <Input
                    id="password"
                    name="password"
                    type="password"
                    value={formData.password}
                    onChange={handleChange}
                    placeholder="Enter password"
                    className={`pl-10 h-12 rounded-xl ${errors.password ? 'border-destructive' : ''}`}
                  />
                </div>
                {formData.password && <PasswordCriteria criteria={passwordCriteria} />}
                {errors.password && !formData.password && <p className="text-xs text-destructive">{errors.password}</p>}
              </div>

              {/* Confirm Password */}
              <div className="space-y-2">
                <Label htmlFor="confirmPassword">Confirm Password</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground w-5 h-5" />
                  <Input
                    id="confirmPassword"
                    name="confirmPassword"
                    type="password"
                    value={formData.confirmPassword}
                    onChange={handleChange}
                    placeholder="Confirm password"
                    className={`pl-10 h-12 rounded-xl ${errors.confirmPassword ? 'border-destructive' : ''}`}
                  />
                </div>
                {errors.confirmPassword && <p className="text-xs text-destructive">{errors.confirmPassword}</p>}
              </div>

              {/* Terms */}
              <div className="flex items-center text-sm">
                <Checkbox id="terms" checked={acceptTerms} onCheckedChange={setAcceptTerms} />
                <Label htmlFor="terms" className="ml-2 text-muted-foreground">
                  I agree to the <Link to="/terms" className="text-primary hover:underline">Terms of Service</Link> & <Link to="/privacy" className="text-primary hover:underline">Privacy Policy</Link>
                </Label>
              </div>
              {errors.terms && <p className="text-xs text-destructive">{errors.terms}</p>}

              {/* Submit Button */}
              <Button type="submit" className="w-full h-12 rounded-xl shadow-lg text-base font-semibold hover:shadow-xl transition-all" disabled={loading}>
                {loading ? "Creating Account..." : <>Create Account <ArrowRight className="w-4 h-4 ml-2" /></>}
              </Button>
            </form>

            {/* Divider & Sign In Link */}
            <div className="relative mt-4">
              <div className="absolute inset-0 flex items-center">
                <Separator className="w-full" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-card px-2 text-muted-foreground">Already have an account?</span>
              </div>
            </div>
            <div className="text-center mt-2">
              <Link to="/signin" className="text-sm font-semibold text-primary hover:underline">
                Sign in to your account
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default Register;