import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "@/lib/firebase";
import { doc, updateDoc } from "firebase/firestore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Separator } from "@/components/ui/separator";
import { useToast } from "@/hooks/use-toast";
import { Mail, Lock, ArrowRight, Eye, EyeOff } from "lucide-react";

const SignIn = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleSignIn = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // 🔹 Update staff document to set online status
      await updateDoc(doc(db, "staff", user.uid), {
        online: true,
        lastSeen: new Date(),
      });

      toast({
        title: "Success! ✅",
        description: "You have been signed in successfully.",
      });
      navigate("/"); // Redirect to dashboard
    } catch (error) {
      toast({
        title: "Authentication Error ⚠️",
        description: "Invalid email or password. Please try again.",
        variant: "destructive",
      });
      console.error("Firebase Auth Error:", error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-background via-muted to-background px-4">
      <div className="w-full max-w-lg">
        <Card className="backdrop-blur-xl bg-card/70 border border-border/40 shadow-2xl rounded-2xl">p
          <CardHeader className="text-center space-y-3 pb-6">~
            {/* Logo */}
            <img
              src="/zesty-logo.png"
              alt="Zesty Logo"
              className="mx-auto w-32 h-32 object-contain"
            />

            <div className="space-y-1">
              <CardTitle className="text-3xl font-extrabold bg-gradient-to-r from-primary to-purple-500 bg-clip-text text-transparent">
                Welcome Back
              </CardTitle>
              <CardDescription className="text-base text-muted-foreground">
                Sign in to access your <span className="font-medium text-foreground">Zesty Dashboard</span>
              </CardDescription>
            </div>
          </CardHeader>

          <CardContent className="space-y-6">
            <form onSubmit={handleSignIn} className="space-y-6">
              {/* Email */}
              <div className="space-y-2">
                <Label htmlFor="email">Email Address</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground w-5 h-5" />
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    className="pl-10 h-12 rounded-xl focus-visible:ring-2 focus-visible:ring-primary transition-all"
                    required
                  />
                </div>
              </div>

              {/* Password */}
              <div className="space-y-2">
                <Label htmlFor="password">Password</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground w-5 h-5" />
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter your password"
                    className="pl-10 pr-12 h-12 rounded-xl focus-visible:ring-2 focus-visible:ring-primary transition-all"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              {/* Remember Me */}
              <div className="flex items-center text-sm">
                <Checkbox id="remember" />
                <Label htmlFor="remember" className="ml-2 text-muted-foreground">
                  Remember me
                </Label>
              </div>

              {/* Submit */}
              <Button
                type="submit"
                className="w-full h-12 text-base font-semibold rounded-xl shadow-lg hover:shadow-xl transition-all"
                disabled={loading}
              >
                {loading ? "Signing in..." : <>Sign In <ArrowRight className="w-4 h-4 ml-2" /></>}
              </Button>
            </form>

            {/* Divider */}
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <Separator className="w-full" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-card px-2 text-muted-foreground">New to Zesty?</span>
              </div>
            </div>

            {/* Register Link */}
            <div className="text-center">
              <span className="text-sm text-muted-foreground">Don’t have an account? </span>
              <Link to="/register" className="text-sm font-semibold text-primary hover:underline">
                Create your account
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SignIn;
