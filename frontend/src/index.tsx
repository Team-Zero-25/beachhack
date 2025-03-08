import React from 'react';
import { Compass, Map, Star, Users, Search, ArrowRight } from 'lucide-react';


function App() {
  return (
    <div className="min-h-screen bg-white">
      {/* Hero Section */}
      <div 
        className="relative h-screen bg-cover bg-center"
        style={{
          backgroundImage: 'url("https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&q=80&w=2400")',
        }}
      >
        <div className="absolute inset-0 bg-black bg-opacity-50">
          <div className="container mx-auto px-6 h-full flex flex-col justify-center">
            <h1 className="text-5xl md:text-7xl font-bold text-white mb-6">
              Discover Your Next
              <span className="block text-emerald-400">Adventure</span>
            </h1>
            
            {/* Search Bar */}
            <div className="bg-white p-2 rounded-full shadow-lg max-w-3xl flex items-center">
              <Search className="ml-4 text-gray-500" size={24} />
              <input
                type="text"
                placeholder="Where do you want to go?"
                className="w-full px-4 py-2 outline-none"
              />
              <button className="bg-emerald-500 text-white px-8 py-3 rounded-full hover:bg-emerald-600 transition duration-300">
                Explore
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="py-20 bg-gray-50">
        <div className="container mx-auto px-6">
          <div className="grid md:grid-cols-3 gap-12">
            <div className="text-center">
              <div className="bg-emerald-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-6">
                <Map className="text-emerald-600" size={32} />
              </div>
              <h3 className="text-xl font-semibold mb-4">Expert Guides</h3>
              <p className="text-gray-600">Get insider tips and detailed itineraries from our travel experts.</p>
            </div>
            <div className="text-center">
              <div className="bg-emerald-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-6">
                <Star className="text-emerald-600" size={32} />
              </div>
              <h3 className="text-xl font-semibold mb-4">Verified Reviews</h3>
              <p className="text-gray-600">Real experiences shared by our community of travelers.</p>
            </div>
            <div className="text-center">
              <div className="bg-emerald-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-6">
                <Users className="text-emerald-600" size={32} />
              </div>
              <h3 className="text-xl font-semibold mb-4">Local Experiences</h3>
              <p className="text-gray-600">Connect with locals and discover authentic experiences.</p>
            </div>
          </div>
        </div>
      </div>

      {/* Popular Destinations */}
      <div className="py-20">
        <div className="container mx-auto px-6">
          <h2 className="text-4xl font-bold text-center mb-16">Popular Destinations</h2>
          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                name: "Santorini, Greece",
                image: "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&q=80&w=800",
                rating: "4.9"
              },
              {
                name: "Bali, Indonesia",
                image: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&q=80&w=800",
                rating: "4.8"
              },
              {
                name: "Machu Picchu, Peru",
                image: "https://images.unsplash.com/photo-1587595431973-160d0d94add1?auto=format&fit=crop&q=80&w=800",
                rating: "4.9"
              }
            ].map((destination, index) => (
              <div key={index} className="group cursor-pointer">
                <div className="relative overflow-hidden rounded-xl">
                  <img 
                    src={destination.image} 
                    alt={destination.name}
                    className="w-full h-80 object-cover transform group-hover:scale-110 transition duration-500"
                  />
                  <div className="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black to-transparent">
                    <h3 className="text-xl text-white font-semibold">{destination.name}</h3>
                    <div className="flex items-center text-yellow-400 mt-2">
                      <Star size={16} fill="currentColor" />
                      <span className="ml-2 text-white">{destination.rating}</span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="bg-emerald-500 py-20">
        <div className="container mx-auto px-6 text-center">
          <h2 className="text-4xl font-bold text-white mb-8">Ready to Start Your Journey?</h2>
          <p className="text-white text-xl mb-8 max-w-2xl mx-auto">
            Join thousands of travelers who trust us to plan their perfect trip.
          </p>
          <button className="bg-white text-emerald-500 px-8 py-4 rounded-full text-lg font-semibold hover:bg-gray-100 transition duration-300 flex items-center mx-auto">
            Plan Your Trip Now
            <ArrowRight className="ml-2" size={20} />
          </button>
        </div>
      </div>
    </div>
  );
}

export default App;