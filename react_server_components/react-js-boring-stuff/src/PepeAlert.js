'use client';

import {useState} from 'react';

const FileErrorAlert = ({errorCode}) => {
  // Error messages mapping based on common file system error codes
  const getErrorDetails = (code) => {
    const errorMap = {
      1: {
        title: 'Operation not permitted',
      },
      2: {
        title: 'No such file or directory',
      },
      3: {
        title: 'No such process',
      },
      4: {
        title: 'Interrupted system call',
      },
      5: {
        title: 'I/O Error',
      },
      13: {
        title: 'Permission Denied',
      },
      17: {
        title: 'File exists',
      },
      21: {
        title: 'Is a directory',
      },
      22: {
        title: 'Invalid argument',
      },
      28: {
        title: 'No space left',
      },
      // Add more error codes as needed
      default: {
        title: 'Unknown Error',
      },
    };

    return errorMap[code] || errorMap.default;
  };

  const [count, setCount] = useState(0);
  const {title, message} = getErrorDetails(errorCode);
  return (
    <div className="error-card">
      <div className="error-content">
        {/* Pepe Image */}
        <div className="error-image-container">
          <img
            src="ok-hand-pepe.gif" // Replace with your Pepe image path
            alt="Error Pepe"
            className="error-image"
          />
        </div>

        <div className="error-details">
          <div className="error-header">
            <div>
              <h3 className="error-title">{title}</h3>
              <span className="error-code">Error Code: {errorCode}</span>
            </div>
            <button className="close-button">
              <svg
                className="close-icon"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
          <div className="counter-container">
            <button
              className="counter-button"
              onClick={() => setCount((c) => c - 1)}>
              --
            </button>
            <span className="counter-display">[{count}]</span>
            <button
              className="counter-button"
              onClick={() => setCount((c) => c + 1)}>
              ++
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FileErrorAlert;
