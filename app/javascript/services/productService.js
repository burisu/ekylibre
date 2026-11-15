import http from "lib/http";
class ProductService {
  get(id) {
    return http.get(`/backend/products/${id}.json`).then((res) => res.data);
  }
}
export {
  ProductService
};
