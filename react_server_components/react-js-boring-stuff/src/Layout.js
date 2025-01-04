import React from 'react';

export const Layout = ({children}) => {
  return (
    <div className="layout-container">
      <div className="logo-container">
        <img src="logo.svg" alt="React logo" className="react-logo" />
      </div>
      <div className="pepe-container">
        <img src="pepe.png" alt="Pepe pointing" className="pepe-pointing" />
      </div>

      {children}

      <h1 className="assembly-header">
        ; React Server Components ; ---------------------- ; Version 1.0 section
        .text
      </h1>
    </div>
  );
};
