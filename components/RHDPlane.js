import PropTypes from "prop-types";
import RHDGeometry from "./RHDGeometry";
export default RHDGeometry("Plane", {
  width: PropTypes.number,
  height: PropTypes.number,
  cornerRadius: PropTypes.number,
  cornerSegmentCount: PropTypes.number,
  widthSegmentCount: PropTypes.number,
  heightSegmentCount: PropTypes.number
});