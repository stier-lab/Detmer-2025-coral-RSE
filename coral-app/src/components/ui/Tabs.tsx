import React, { createContext, useContext, useState } from 'react';
import { clsx } from 'clsx';

interface TabsContextType {
  activeTab: string;
  setActiveTab: (id: string) => void;
}

const TabsContext = createContext<TabsContextType | undefined>(undefined);

const useTabsContext = () => {
  const context = useContext(TabsContext);
  if (!context) {
    throw new Error('Tabs components must be used within a Tabs provider');
  }
  return context;
};

export interface TabsProps {
  defaultValue?: string;
  value?: string;
  onValueChange?: (value: string) => void;
  children: React.ReactNode;
  className?: string;
}

export const Tabs: React.FC<TabsProps> = ({
  defaultValue,
  value: controlledValue,
  onValueChange,
  children,
  className
}) => {
  const [internalValue, setInternalValue] = useState(defaultValue || '');

  const activeTab = controlledValue !== undefined ? controlledValue : internalValue;

  const setActiveTab = (newValue: string) => {
    if (controlledValue === undefined) {
      setInternalValue(newValue);
    }
    onValueChange?.(newValue);
  };

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className={clsx('flex flex-col', className)}>{children}</div>
    </TabsContext.Provider>
  );
};

export interface TabsListProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

export const TabsList: React.FC<TabsListProps> = ({ children, className, ...props }) => {
  return (
    <div
      role="tablist"
      className={clsx(
        'inline-flex gap-1 p-1 bg-gray-100 rounded-lg',
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
};

export interface TabsTriggerProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  value: string;
  children: React.ReactNode;
}

export const TabsTrigger: React.FC<TabsTriggerProps> = ({
  value,
  children,
  className,
  onClick,
  ...props
}) => {
  const { activeTab, setActiveTab } = useTabsContext();
  const isActive = activeTab === value;

  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    setActiveTab(value);
    onClick?.(e);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLButtonElement>) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      setActiveTab(value);
    }
  };

  return (
    <button
      role="tab"
      aria-selected={isActive}
      aria-controls={`panel-${value}`}
      tabIndex={isActive ? 0 : -1}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      className={clsx(
        'px-4 py-2 rounded-md text-sm font-medium transition-all',
        'focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-1',
        {
          'bg-white text-primary-600 shadow-sm': isActive,
          'text-gray-600 hover:text-gray-900 hover:bg-gray-50': !isActive,
        },
        className
      )}
      {...props}
    >
      {children}
    </button>
  );
};

export interface TabsContentProps extends React.HTMLAttributes<HTMLDivElement> {
  value: string;
  children: React.ReactNode;
}

export const TabsContent: React.FC<TabsContentProps> = ({
  value,
  children,
  className,
  ...props
}) => {
  const { activeTab } = useTabsContext();
  const isActive = activeTab === value;

  if (!isActive) return null;

  return (
    <div
      role="tabpanel"
      id={`panel-${value}`}
      aria-labelledby={`tab-${value}`}
      className={clsx('mt-4 animate-in', className)}
      {...props}
    >
      {children}
    </div>
  );
};
