import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from './App';

describe('App', () => {
  it('renders the application header', () => {
    render(<App />);
    // Use getByRole to target the h1 heading specifically
    expect(screen.getByRole('heading', { level: 1, name: /Coral Restoration/i })).toBeInTheDocument();
  });

  it('renders navigation tabs', () => {
    render(<App />);
    expect(screen.getByText(/Overview/i)).toBeInTheDocument();
    expect(screen.getByText(/Parameters/i)).toBeInTheDocument();
    expect(screen.getByText(/Results/i)).toBeInTheDocument();
  });

  it('renders size class information', () => {
    render(<App />);
    expect(screen.getByText(/Size Classes/i)).toBeInTheDocument();
  });
});
