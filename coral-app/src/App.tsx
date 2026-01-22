import { useState } from 'react';
import { runSimulation, calculateSummaryStats } from './lib/model/simulation';
import type { SimulationSummary } from './lib/model/simulation';
import { DEFAULT_REEF_PARAMS, DEFAULT_ORCHARD_PARAMS, DEFAULT_MANAGEMENT_PARAMS } from './lib/constants';
import type { SimulationConfig, PopulationVector, SimulationState } from './types/model';
import './styles/globals.css';

interface SimulationResults {
  trajectory: SimulationState[];
  summary: SimulationSummary;
}

function App() {
  const [simulationYears, setSimulationYears] = useState(50);
  const [results, setResults] = useState<SimulationResults | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  const initialReefPop: PopulationVector = {
    sc1: 100,
    sc2: 50,
    sc3: 20,
    sc4: 5,
    sc5: 1
  };

  const initialOrchardPop: PopulationVector = {
    sc1: 0,
    sc2: 0,
    sc3: 0,
    sc4: 0,
    sc5: 0
  };

  const handleRunSimulation = () => {
    const config: SimulationConfig = {
      years: simulationYears,
      initialPopulation: {
        reef: initialReefPop,
        orchard: initialOrchardPop
      },
      compartmentParams: {
        reef: DEFAULT_REEF_PARAMS,
        orchard: DEFAULT_ORCHARD_PARAMS
      },
      managementParams: DEFAULT_MANAGEMENT_PARAMS
    };

    const simResults = runSimulation(config);
    const summary = calculateSummaryStats(simResults);
    setResults({ trajectory: simResults, summary });
    setActiveTab('results');
  };

  return (
    <div className="min-h-screen relative p-6 md:p-12">
      {/* Header */}
      <header className="text-center mb-12 fade-in relative z-10">
        <div className="inline-block">
          <h1 className="text-5xl md:text-7xl font-bold mb-4" style={{
            background: 'linear-gradient(135deg, #fdfbf7 0%, #ff6b9d 50%, #ff8c42 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text',
          }}>
            Coral Restoration
          </h1>
          <div className="h-1 bg-gradient-to-r from-transparent via-pink-300 to-transparent rounded-full"></div>
        </div>
        <p className="text-xl md:text-2xl mt-6 text-white/80 font-light" style={{ fontFamily: 'Crimson Pro, serif' }}>
          Population Dynamics Model for <em>Acropora palmata</em>
        </p>
      </header>

      {/* Navigation */}
      <nav className="frosted rounded-2xl p-2 mb-8 max-w-5xl mx-auto relative z-10 fade-in stagger-1">
        <div className="flex gap-2">
          {[
            { id: 'overview', label: 'System Overview', icon: '🌊' },
            { id: 'parameters', label: 'Parameters', icon: '⚙️' },
            { id: 'results', label: 'Results', icon: '📊' },
            { id: 'about', label: 'About', icon: '📖' }
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex-1 px-4 py-3 rounded-xl font-medium transition-all duration-300 ${
                activeTab === tab.id
                  ? 'bg-gradient-to-r from-pink-500 to-orange-500 text-white shadow-lg'
                  : 'text-gray-900 hover:bg-white/50'
              }`}
              style={{ fontFamily: 'Crimson Pro, serif' }}
            >
              <span className="mr-2">{tab.icon}</span>
              <span className="hidden sm:inline">{tab.label}</span>
            </button>
          ))}
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto relative z-10">
        {/* Overview Tab */}
        {activeTab === 'overview' && (
          <div className="space-y-8 fade-in">
            <section className="frosted rounded-3xl p-8 md:p-12">
              <h2 className="text-3xl md:text-4xl font-bold mb-8 text-gray-900">Restoration Pathways</h2>

              <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
                {[
                  {
                    title: 'External Reefs',
                    icon: '🌍',
                    color: 'from-emerald-400 to-teal-600',
                    description: 'Wild reference reefs providing larvae for collection'
                  },
                  {
                    title: 'Lab Facility',
                    icon: '🔬',
                    color: 'from-blue-400 to-indigo-600',
                    description: 'Settlement facility for larvae rearing on substrates'
                  },
                  {
                    title: 'Orchard Nursery',
                    icon: '🌿',
                    color: 'from-cyan-400 to-blue-600',
                    description: 'Protected nursery for growing corals to transplantable sizes'
                  },
                  {
                    title: 'Restoration Reef',
                    icon: '🪸',
                    color: 'from-pink-400 to-rose-600',
                    description: 'Target restoration site for coral outplanting'
                  }
                ].map((item, i) => (
                  <div
                    key={item.title}
                    className={`fade-in stagger-${i + 1} group relative overflow-hidden rounded-2xl p-6 bg-white/90 hover:bg-white transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl cursor-pointer`}
                  >
                    <div className={`absolute inset-0 bg-gradient-to-br ${item.color} opacity-0 group-hover:opacity-10 transition-opacity duration-300`}></div>
                    <div className="relative z-10">
                      <div className={`w-20 h-20 rounded-full bg-gradient-to-br ${item.color} flex items-center justify-center text-4xl mb-4 mx-auto group-hover:scale-110 transition-transform duration-300`}>
                        {item.icon}
                      </div>
                      <h3 className="text-xl font-bold mb-2 text-center text-gray-900">{item.title}</h3>
                      <p className="text-sm text-gray-800 text-center leading-relaxed">{item.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </section>

            <section className="frosted rounded-3xl p-8 md:p-12">
              <h2 className="text-3xl md:text-4xl font-bold mb-8 text-gray-900">Size Classes</h2>
              <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                {[
                  { id: 'SC1', range: '0-10 cm²', color: 'from-green-400 to-emerald-600' },
                  { id: 'SC2', range: '10-100 cm²', color: 'from-blue-400 to-blue-600' },
                  { id: 'SC3', range: '100-900 cm²', color: 'from-purple-400 to-purple-600' },
                  { id: 'SC4', range: '900-4000 cm²', color: 'from-orange-400 to-orange-600' },
                  { id: 'SC5', range: '>4000 cm²', color: 'from-red-400 to-red-600' }
                ].map((sc, i) => (
                  <div
                    key={sc.id}
                    className={`fade-in stagger-${i + 1} rounded-xl p-4 bg-gradient-to-br ${sc.color} text-white text-center hover:scale-105 transition-transform duration-300 cursor-pointer`}
                  >
                    <div className="text-2xl font-bold mb-1">{sc.id}</div>
                    <div className="text-sm opacity-90">{sc.range}</div>
                  </div>
                ))}
              </div>
            </section>
          </div>
        )}

        {/* Parameters Tab */}
        {activeTab === 'parameters' && (
          <div className="fade-in">
            <div className="frosted rounded-3xl p-8 md:p-12 max-w-5xl mx-auto">
              <h2 className="text-3xl md:text-4xl font-bold mb-8 text-gray-900">Simulation Parameters</h2>

              <div className="space-y-6">
                <div>
                  <label className="flex items-center justify-between mb-3">
                    <span className="text-lg font-medium text-gray-900">Simulation Duration</span>
                    <span className="text-2xl font-bold bg-gradient-to-r from-pink-500 to-orange-500 bg-clip-text text-transparent">
                      {simulationYears} years
                    </span>
                  </label>
                  <input
                    type="range"
                    min="10"
                    max="100"
                    step="5"
                    value={simulationYears}
                    onChange={(e) => setSimulationYears(parseInt(e.target.value))}
                    className="w-full h-3 bg-gray-200 rounded-full appearance-none cursor-pointer slider"
                    style={{
                      background: `linear-gradient(to right, #ff6b9d 0%, #ff6b9d ${(simulationYears - 10) / 0.9}%, #e5e7eb ${(simulationYears - 10) / 0.9}%, #e5e7eb 100%)`
                    }}
                  />
                  <p className="text-sm text-gray-700 mt-2">Number of years to project population dynamics</p>
                </div>

                <button
                  onClick={handleRunSimulation}
                  className="w-full mt-8 px-8 py-4 rounded-xl bg-gradient-to-r from-pink-500 to-orange-500 text-white font-bold text-lg hover:shadow-2xl hover:scale-105 transition-all duration-300 relative overflow-hidden group"
                >
                  <span className="relative z-10">▶ Run Simulation</span>
                  <div className="absolute inset-0 bg-gradient-to-r from-pink-600 to-orange-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Results Tab */}
        {activeTab === 'results' && (
          <div className="fade-in">
            {!results ? (
              <div className="frosted rounded-3xl p-12 text-center max-w-4xl mx-auto">
                <div className="text-8xl mb-6">📊</div>
                <h3 className="text-2xl font-bold mb-4 text-gray-900">No simulation results yet</h3>
                <p className="text-gray-800 mb-6">Configure your parameters and run a simulation to see population dynamics</p>
                <button
                  onClick={() => setActiveTab('parameters')}
                  className="px-6 py-3 rounded-xl bg-gradient-to-r from-pink-500 to-orange-500 text-white font-medium hover:shadow-lg transition-all duration-300"
                >
                  Go to Parameters
                </button>
              </div>
            ) : (
              <div className="space-y-6">
                <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
                  {[
                    {
                      label: 'Final Population',
                      value: Math.round(results.summary.finalPopulation).toLocaleString(),
                      unit: 'colonies',
                      color: 'from-emerald-400 to-teal-600'
                    },
                    {
                      label: 'Peak Population',
                      value: Math.round(results.summary.peakPopulation).toLocaleString(),
                      unit: `at year ${results.summary.peakYear}`,
                      color: 'from-blue-400 to-indigo-600'
                    },
                    {
                      label: 'Final Coral Cover',
                      value: (results.summary.finalCoralCover / 10000).toFixed(1),
                      unit: 'm²',
                      color: 'from-purple-400 to-purple-600'
                    },
                    {
                      label: 'Mean Growth Rate',
                      value: (results.summary.meanGrowthRate * 100).toFixed(1) + '%',
                      unit: 'per year',
                      color: 'from-pink-400 to-rose-600'
                    }
                  ].map((metric, i) => (
                    <div
                      key={metric.label}
                      className={`fade-in stagger-${i + 1} frosted rounded-2xl p-6 hover:shadow-2xl hover:-translate-y-1 transition-all duration-300`}
                    >
                      <div className="text-sm text-gray-800 mb-2">{metric.label}</div>
                      <div className={`text-4xl font-bold mb-1 bg-gradient-to-r ${metric.color} bg-clip-text text-transparent`}>
                        {metric.value}
                      </div>
                      <div className="text-xs text-gray-700">{metric.unit}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* About Tab */}
        {activeTab === 'about' && (
          <div className="fade-in">
            <div className="frosted rounded-3xl p-8 md:p-12 max-w-5xl mx-auto">
              <h2 className="text-3xl md:text-4xl font-bold mb-8 text-gray-900">About This Model</h2>

              <div className="prose prose-lg max-w-none">
                <p className="text-gray-900 leading-relaxed mb-6">
                  This is a stage-structured population dynamics model for coral restoration,
                  specifically designed for <em>Acropora palmata</em> (Elkhorn Coral).
                </p>

                <h3 className="text-2xl font-bold mb-4 text-gray-900">Core Equation</h3>
                <div className="bg-gradient-to-r from-pink-50 to-orange-50 rounded-xl p-6 mb-6 text-center border-2 border-pink-200">
                  <code className="text-xl md:text-2xl font-mono text-gray-900">
                    N(t+1) = S · (T + F) · N(t) + R
                  </code>
                </div>

                <p className="text-gray-900 mb-4">Where:</p>
                <ul className="space-y-3 mb-8">
                  <li className="flex items-start">
                    <span className="inline-block w-6 h-6 rounded-full bg-gradient-to-r from-pink-400 to-pink-600 text-white text-center font-bold mr-3 flex-shrink-0">S</span>
                    <span className="text-gray-900">Survival matrix (size-specific survival rates)</span>
                  </li>
                  <li className="flex items-start">
                    <span className="inline-block w-6 h-6 rounded-full bg-gradient-to-r from-blue-400 to-blue-600 text-white text-center font-bold mr-3 flex-shrink-0">T</span>
                    <span className="text-gray-900">Transition matrix (growth, shrinkage, stasis)</span>
                  </li>
                  <li className="flex items-start">
                    <span className="inline-block w-6 h-6 rounded-full bg-gradient-to-r from-purple-400 to-purple-600 text-white text-center font-bold mr-3 flex-shrink-0">F</span>
                    <span className="text-gray-900">Fragmentation matrix (asexual reproduction)</span>
                  </li>
                  <li className="flex items-start">
                    <span className="inline-block w-6 h-6 rounded-full bg-gradient-to-r from-orange-400 to-orange-600 text-white text-center font-bold mr-3 flex-shrink-0">R</span>
                    <span className="text-gray-900">Recruitment vector (new settlers)</span>
                  </li>
                </ul>

                <h3 className="text-2xl font-bold mb-4 text-gray-900">Model Features</h3>
                <ul className="space-y-2 text-gray-900">
                  <li>✓ Five size classes based on colony planar area</li>
                  <li>✓ Three compartments: REEF, ORCHARD, LAB</li>
                  <li>✓ Carrying capacity constraints</li>
                  <li>✓ Larval production and collection</li>
                  <li>✓ Outplanting strategies</li>
                </ul>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="text-center mt-16 text-white/60 text-sm relative z-10">
        <p className="fade-in stagger-4">Coral Restoration Model · Adrian Stier Lab · 2026</p>
      </footer>

      <style>{`
        input[type="range"]::-webkit-slider-thumb {
          appearance: none;
          width: 24px;
          height: 24px;
          border-radius: 50%;
          background: linear-gradient(135deg, #ff6b9d, #ff8c42);
          cursor: pointer;
          box-shadow: 0 4px 12px rgba(255, 107, 157, 0.4);
          transition: all 0.3s ease;
        }

        input[type="range"]::-webkit-slider-thumb:hover {
          transform: scale(1.2);
          box-shadow: 0 6px 20px rgba(255, 107, 157, 0.6);
        }

        input[type="range"]::-moz-range-thumb {
          width: 24px;
          height: 24px;
          border-radius: 50%;
          background: linear-gradient(135deg, #ff6b9d, #ff8c42);
          cursor: pointer;
          border: none;
          box-shadow: 0 4px 12px rgba(255, 107, 157, 0.4);
          transition: all 0.3s ease;
        }

        input[type="range"]::-moz-range-thumb:hover {
          transform: scale(1.2);
          box-shadow: 0 6px 20px rgba(255, 107, 157, 0.6);
        }
      `}</style>
    </div>
  );
}

export default App;
