import React, { useState } from 'react';
import { useAuth } from './AuthContext';

// Sample user database
type VehicleType = '2_wheeler' | '3_wheeler' | '4_wheeler';

const SAMPLE_USERS: Array<{
  name: string;
  username: string;
  password: string;
  vehicleNumber: string;
  licenseNumber: string;
  seats: number;
  vehicleType: VehicleType;
}> = [
  {
    name: "John Doe",
    username: "john",
    password: "123",
    vehicleNumber: "KL-01-AB-1234",
    licenseNumber: "DL98765432",
    seats: 2,
    vehicleType: "2_wheeler" as const
  },
  {
    name: "Jane Smith",
    username: "jane",
    password: "123",
    vehicleNumber: "KL-05-CD-5678",
    licenseNumber: "DL12345678",
    seats: 4,
    vehicleType: "4_wheeler" as const
  }
];

const Auth: React.FC = () => {
  const { login } = useAuth();
  const [isRegister, setIsRegister] = useState(false);
  const [formData, setFormData] = useState({
    username: '',
    password: '',
    name: '',
    vehicleNumber: '',
    licenseNumber: '',
    seats: 2,
    vehicleType: '2_wheeler' as '2_wheeler' | '3_wheeler' | '4_wheeler'
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (isRegister) {
      // Registration logic
      const newUser = {
        ...formData
      };
      // In a real app, you would save to a database
      SAMPLE_USERS.push(newUser);
      alert('Registration successful! Please login.');
      setIsRegister(false);
    } else {
      // Login logic
      const user = SAMPLE_USERS.find(u => 
        u.username === formData.username && u.password === formData.password
      );
      
      if (user) {
        login({
          name: user.name,
          vehicleNumber: user.vehicleNumber,
          licenseNumber: user.licenseNumber,
          seats: user.seats,
          vehicleType: user.vehicleType
        });
      } else {
        alert('Invalid credentials!');
      }
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8 bg-white p-8 rounded-lg shadow">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {isRegister ? 'Register as a Driver' : 'Sign in to your account'}
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            {isRegister ? 'Already have an account? ' : "Don't have an account? "}
            <button
              type="button"
              onClick={() => setIsRegister(!isRegister)}
              className="font-medium text-blue-600 hover:text-blue-500"
            >
              {isRegister ? 'Login' : 'Register'}
            </button>
          </p>
        </div>

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="rounded-md shadow-sm space-y-4">
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-gray-700">
                Username
              </label>
              <input
                id="username"
                name="username"
                type="text"
                required
                value={formData.username}
                onChange={(e) => setFormData({...formData, username: e.target.value})}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                required
                value={formData.password}
                onChange={(e) => setFormData({...formData, password: e.target.value})}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
              />
            </div>

            {isRegister && (
              <>
                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                    Full Name
                  </label>
                  <input
                    id="name"
                    name="name"
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({...formData, name: e.target.value})}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
                  />
                </div>

                <div>
                  <label htmlFor="vehicleNumber" className="block text-sm font-medium text-gray-700">
                    Vehicle Number
                  </label>
                  <input
                    id="vehicleNumber"
                    name="vehicleNumber"
                    type="text"
                    required
                    placeholder="KL-01-AB-1234"
                    value={formData.vehicleNumber}
                    onChange={(e) => setFormData({...formData, vehicleNumber: e.target.value})}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
                  />
                </div>

                <div>
                  <label htmlFor="licenseNumber" className="block text-sm font-medium text-gray-700">
                    License Number
                  </label>
                  <input
                    id="licenseNumber"
                    name="licenseNumber"
                    type="text"
                    required
                    value={formData.licenseNumber}
                    onChange={(e) => setFormData({...formData, licenseNumber: e.target.value})}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
                  />
                </div>

                <div>
                  <label htmlFor="vehicleType" className="block text-sm font-medium text-gray-700">
                    Vehicle Type
                  </label>
                  <select
                    id="vehicleType"
                    name="vehicleType"
                    required
                    value={formData.vehicleType}
                    onChange={(e) => setFormData({...formData, vehicleType: e.target.value as any})}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
                  >
                    <option value="2_wheeler">2 Wheeler</option>
                    <option value="3_wheeler">3 Wheeler</option>
                    <option value="4_wheeler">4 Wheeler</option>
                  </select>
                </div>

                <div>
                  <label htmlFor="seats" className="block text-sm font-medium text-gray-700">
                    Number of Seats
                  </label>
                  <input
                    id="seats"
                    name="seats"
                    type="number"
                    min="1"
                    max="8"
                    required
                    value={formData.seats}
                    onChange={(e) => setFormData({...formData, seats: parseInt(e.target.value)})}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md"
                  />
                </div>
              </>
            )}
          </div>

          <div>
            <button
              type="submit"
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              {isRegister ? 'Register' : 'Sign in'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Auth;
